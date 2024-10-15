import json
import os
import shlex
import subprocess
import sys
import urllib.request


def get_pat():
    """Retrieves the GitHub PAT from AWS SSM."""
    try:
        process = subprocess.run(
            ["ec2metadata", "--availability-zone"], capture_output=True, text=True, check=True)
        aws_region = process.stdout.strip()[:-1]

        command = [
            "aws", "ssm", "get-parameter", "--name", "github_pat", "--with-decryption",
            "--region", aws_region, "--query", "Parameter.Value", "--output", "text"
        ]
        process = subprocess.run(
            command, capture_output=True, text=True, check=True)
        return process.stdout.strip()

    except subprocess.CalledProcessError as e:
        print(f"Error retrieving PAT: {e}")
        sys.exit(1)


def get_runner_token(github_pat, github_repo):
    """Retrieves a GitHub registration token."""
    req = urllib.request.Request(
        f"https://api.github.com/repos/{
            github_repo}/actions/runners/registration-token",
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {github_pat}",
            "X-GitHub-Api-Version": "2022-11-28"
        },
        method="POST"
    )
    with urllib.request.urlopen(req) as response:
        return json.load(response)["token"]


def configure_runner(github_repo, token):
    command = f"./config.sh --unattended --url https://github.com/{
        github_repo} --token {token} --name ec2-runner"
    subprocess.run(shlex.split(command), check=True)
    subprocess.Popen("./run.sh")


def remove_runner(token):
    command = f"./config.sh remove --token {token}"
    subprocess.run(shlex.split(command), check=True)


if __name__ == "__main__":
    os.chdir(os.path.expanduser("~/actions-runner"))
    github_repo = os.environ["GITHUB_REPO"]
    github_pat = get_pat()
    token = get_runner_token(github_pat, github_repo)

    if sys.argv[1] == "configure":
        configure_runner(github_repo, token)
    elif sys.argv[1] == "remove":
        remove_runner(token)
