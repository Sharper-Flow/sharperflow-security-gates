from fastapi import FastAPI, Request
import os
import subprocess
import requests

app = FastAPI()


@app.get("/run")
def run_command(command: str):
    # ruleid: sharperflow-fastapi-tainted-process
    subprocess.run(command, shell=True)


@app.get("/system")
def system_command(command: str):
    # ruleid: sharperflow-fastapi-tainted-process
    os.system(command)


@app.get("/fetch")
def fetch_url(url: str):
    # ruleid: sharperflow-fastapi-tainted-ssrf
    requests.get(url)


@app.get("/request-fetch")
def request_fetch(request: Request):
    target = request.query_params["target"]
    # ruleid: sharperflow-fastapi-tainted-ssrf
    requests.post(target)


@app.get("/safe-constant")
def safe_constant():
    # ok: sharperflow-fastapi-tainted-process
    subprocess.run(["/usr/bin/true"], check=True)
    # ok: sharperflow-fastapi-tainted-ssrf
    requests.get("https://example.invalid/health")


@app.get("/safe-wrapper")
def safe_wrapper(command: str):
    allowed = "status"
    # ok: sharperflow-fastapi-tainted-process
    subprocess.run(["/usr/bin/tool", allowed], check=True)
