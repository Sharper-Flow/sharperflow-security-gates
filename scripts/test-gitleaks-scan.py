#!/usr/bin/env python3
"""Exercise the real pinned scanner on disposable histories and wrapper failures."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).resolve().with_name("gitleaks-scan.sh")
IMAGE = "zricethezav/gitleaks:v8.30.0"


class GitleaksScanTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="gitleaks-test-")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        self.env = os.environ | {
            "GIT_AUTHOR_NAME": "Fixture",
            "GIT_AUTHOR_EMAIL": "fixture@example.invalid",
            "GIT_COMMITTER_NAME": "Fixture",
            "GIT_COMMITTER_EMAIL": "fixture@example.invalid",
            "GITLEAKS_IMAGE": IMAGE,
            "GITLEAKS_CONFIG": "",
            "MODE": "full",
            "BASE": "",
            "HEAD": "",
        }
        self.git("init", "-q", "-b", "main")
        self.root = self.commit("root", "base.txt")
        self.main = self.commit("main", "main.txt")

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-C", str(self.repo), *args], env=self.env, text=True
        ).strip()

    def commit(self, message, name=None, content=None):
        if name:
            (self.repo / name).write_text(content or f"{message}\n")
            self.git("add", name)
        self.git("commit", "-qm", message, "--allow-empty")
        return self.git("rev-parse", "HEAD")

    def scan(self, status, count=None, **env):
        result = subprocess.run(
            ["bash", str(SCRIPT)], cwd=self.repo, env=self.env | env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60,
        )
        self.assertEqual(result.returncode, status, result.stdout)
        if count is not None:
            self.assertIn(f"{count} commits scanned", result.stdout, result.stdout)
            self.assertNotIn("::error::", result.stdout, result.stdout)
        return result.stdout

    def off_head_history(self):
        self.git("checkout", "-qb", "unmerged")
        self.commit("branch", "branch.txt")
        self.git("checkout", "-q", "main")
        self.git("checkout", "-qb", "tag-only")
        self.commit("tag", "tag.txt")
        self.git("tag", "kept")
        self.git("checkout", "-q", "main")
        self.git("branch", "-D", "tag-only")
        self.commit("empty")
        self.git("checkout", "-qb", "merged")
        self.commit("merged", "merged.txt")
        self.git("checkout", "-q", "main")
        self.git("merge", "-q", "--no-ff", "merged", "-m", "merge")

    def test_full_counts_branch_tag_merge_and_empty_history(self):
        self.off_head_history()
        self.scan(0, count=5)

    def assert_change_counts(self, full, diff=None):
        self.git("add", "-A")
        changed = self.commit("change")
        self.scan(0, count=2 + full)
        diff = full if diff is None else diff
        if diff:
            self.scan(0, count=diff, MODE="diff", BASE=self.main, HEAD=changed)
        else:
            self.assertIn("has no scannable commits", self.scan(
                1, MODE="diff", BASE=self.main, HEAD=changed,
            ))

    def test_deleted_file_has_no_fragment(self):
        self.git("rm", "main.txt")
        self.assert_change_counts(0)

    def test_pure_rename_has_no_fragment(self):
        self.git("mv", "main.txt", "renamed.txt")
        self.assert_change_counts(0)

    def test_added_empty_file_has_no_fragment(self):
        (self.repo / "empty.txt").touch()
        self.assert_change_counts(0)

    def test_binary_file_has_no_fragment(self):
        (self.repo / "binary.dat").write_bytes(b"\x00\x01\x02fixture\n")
        self.assert_change_counts(0)

    def test_modified_binary_file_has_no_fragment(self):
        binary = self.repo / "binary.dat"
        binary.write_bytes(b"\x00first\n")
        self.git("add", "-A")
        before = self.commit("binary")
        binary.write_bytes(b"\x00second\n")
        self.git("add", "-A")
        changed = self.commit("modified binary")
        self.scan(0, count=2)
        self.assertIn("has no scannable commits", self.scan(
            1, MODE="diff", BASE=before, HEAD=changed,
        ))

    def test_forced_text_binary_bytes_yield_text_fragment(self):
        self.commit("attributes", ".gitattributes", "*.dat diff\n")
        before = self.git("rev-parse", "HEAD")
        (self.repo / "binary.dat").write_bytes(b"\x00fixture\n")
        self.git("add", "-A")
        changed = self.commit("forced text")
        self.scan(0, count=4)
        self.scan(0, count=1, MODE="diff", BASE=before, HEAD=changed)

    def test_binary_archive_has_no_fragment_with_default_depth(self):
        with zipfile.ZipFile(self.repo / "fixture.zip", "w") as archive:
            archive.writestr("clean.txt", "fixture\n")
        self.assert_change_counts(0)

    def test_mode_only_change_has_no_fragment(self):
        (self.repo / "main.txt").chmod(0o755)
        self.assert_change_counts(0)

    def test_type_change_uses_full_filter_but_diff_yields_new_text(self):
        (self.repo / "main.txt").unlink()
        (self.repo / "main.txt").symlink_to("base.txt")
        self.assert_change_counts(0, diff=1)

    def test_symlink_to_empty_file_has_no_surviving_hunk(self):
        link = self.repo / "link"
        link.symlink_to("base.txt")
        self.git("add", "-A")
        before = self.commit("symlink")
        link.unlink()
        link.touch()
        self.git("add", "-A")
        changed = self.commit("empty regular file")
        self.scan(0, count=3)
        self.assertIn("has no scannable commits", self.scan(
            1, MODE="diff", BASE=before, HEAD=changed,
        ))

    def test_removal_only_surviving_file_still_yields_fragment(self):
        (self.repo / "main.txt").write_text("")
        self.assert_change_counts(1)

    def test_mixed_changes_count_commit_once(self):
        self.git("rm", "main.txt")
        self.git("mv", "base.txt", "renamed.txt")
        (self.repo / "empty.txt").touch()
        (self.repo / "binary.dat").write_bytes(b"\x00fixture\n")
        (self.repo / "first.txt").write_text("first\n")
        (self.repo / "second.txt").write_text("second\n")
        self.assert_change_counts(1)

    def test_rename_with_removals_and_quoted_path_yields_fragment(self):
        self.main = self.commit("lines", "lines.txt", "one\ntwo\nthree\nfour\n")
        self.git("mv", "lines.txt", "tab\tand\nnewline.txt")
        (self.repo / "tab\tand\nnewline.txt").write_text("one\ntwo\nthree\n")
        self.git("add", "-A")
        changed = self.commit("rename with removal")
        self.scan(0, count=4)
        self.scan(0, count=1, MODE="diff", BASE=self.main, HEAD=changed)

    def test_off_head_secret_fails_full_but_not_clean_diff(self):
        self.off_head_history()
        self.git("checkout", "-q", "unmerged")
        # Fabricated fixture, not a credential; assemble outside repository source.
        token = "ghp_" + "R9aLq3XzV7mK2pT8wN4yB6cD1fH5jS0uE3gA"
        self.commit("synthetic secret", "secret.txt", f'token = "{token}"\n')
        secret_head = self.git("rev-parse", "HEAD")
        self.git("checkout", "-q", "main")
        output = self.scan(1, count=6)
        self.assertIn("leaks found", output)
        self.assertNotIn(token, output)
        self.scan(0, count=1, MODE="diff", BASE=self.root, HEAD=self.main)
        self.scan(1, count=2, MODE="diff", BASE=self.main, HEAD=secret_head)

    def test_invalid_empty_and_missing_diff_ranges_fail_closed(self):
        for values, message in [
            ({"BASE": self.main, "HEAD": self.main}, "has no scannable commits"),
            ({"BASE": "missing-ref", "HEAD": self.main}, "does not resolve"),
            ({"BASE": self.main, "HEAD": "missing-ref"}, "does not resolve"),
            ({"BASE": "", "HEAD": self.main}, "requires BASE and HEAD"),
        ]:
            with self.subTest(values=values):
                self.assertIn(message, self.scan(1, MODE="diff", **values))
        self.assertIn("MODE must be", self.scan(1, MODE="bogus"))

    def test_config_path_is_resolved_in_caller(self):
        config = self.repo / "caller config.toml"
        config.write_text('[extend]\nuseDefault = true\n')
        self.scan(0, count=2, GITLEAKS_CONFIG=config.name)
        self.assertIn("does not exist", self.scan(1, GITLEAKS_CONFIG="absent.toml"))
        config.write_text("not valid TOML [")
        self.assertIn("could not read", self.scan(1, GITLEAKS_CONFIG=config.name))

    def fake_docker(self, body):
        bindir = Path(self.temp.name) / "bin"
        bindir.mkdir()
        docker = bindir / "docker"
        docker.write_text("#!/usr/bin/env bash\n" + body)
        docker.chmod(0o755)
        return str(bindir) + os.pathsep + self.env["PATH"]

    def test_count_mismatch_fails_closed_even_if_scanner_succeeds(self):
        path = self.fake_docker("printf '1 commits scanned.\\n'; exit 0\n")
        self.assertIn("failing closed", self.scan(1, PATH=path))

    def test_unreadable_count_fails_closed(self):
        path = self.fake_docker("printf 'scanner unavailable\\n'; exit 125\n")
        self.assertIn("could not read", self.scan(1, PATH=path))

    def test_scanner_failure_status_is_preserved_with_matching_count(self):
        path = self.fake_docker("printf '2 commits scanned.\\n'; exit 23\n")
        self.scan(23, count=2, PATH=path)

    def test_git_count_failure_stops_before_scanner(self):
        path = self.fake_docker("printf 'scanner must not run\\n'; exit 0\n")
        git = Path(self.temp.name) / "bin" / "git"
        git.write_text("#!/usr/bin/env bash\nprintf 'count unavailable\\n' >&2\nexit 23\n")
        git.chmod(0o755)
        output = self.scan(23, PATH=path)
        self.assertIn("count unavailable", output)
        self.assertNotIn("scanner must not run", output)


if __name__ == "__main__":
    unittest.main()
