import json
import subprocess
import sys
from pathlib import Path
from zipfile import ZipFile

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from diagrams import Diagram
from diagrams.azure.compute import VM
from diagrams.azure.network import VirtualNetworks
from PIL import Image


def verify_image(path):
    with Image.open(path) as image:
        image.verify()
    with Image.open(path) as image:
        assert image.width > 10 and image.height > 10, path
        assert image.convert("RGB").getextrema() != ((255, 255),) * 3, path


def run_checkov(directory, enabled):
    directory.mkdir()
    directory.joinpath("main.tf").write_text(
        'resource "aws_s3_bucket" "example" { bucket = "toolkit-test" }\n'
        'resource "aws_s3_bucket_versioning" "example" {\n'
        ' bucket = aws_s3_bucket.example.id\n'
        f' versioning_configuration {{ status = "{enabled}" }}\n'
        '}\n',
        encoding="utf-8",
    )
    result = subprocess.run(
        [
            "checkov", "--directory", str(directory), "--framework", "terraform",
            "--check", "CKV_AWS_21", "--skip-download", "--output", "json",
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == (0 if enabled == "Enabled" else 1), result.stderr + result.stdout
    report = json.loads(result.stdout)
    expected = "passed_checks" if enabled == "Enabled" else "failed_checks"
    assert any(item["check_id"] == "CKV_AWS_21" for item in report["results"][expected]), report


def main():
    output = Path(sys.argv[1])
    for file_format in ("svg", "png"):
        with Diagram("Toolkit", filename=str(output / "diagram"), outformat=file_format, show=False):
            VirtualNetworks("Network") >> VM("Compute")
    assert "<svg" in output.joinpath("diagram.svg").read_text(encoding="utf-8")
    verify_image(output / "diagram.png")
    plt.plot([0, 1, 2], [0, 1, 4])
    plt.savefig(output / "plot.png")
    plt.close()
    verify_image(output / "plot.png")
    for name in ("graph.png", "rsvg.png"):
        verify_image(output / name)
    html = output.joinpath("document.html").read_text(encoding="utf-8")
    assert "Acceptance" in html and "graph.png" in html
    with ZipFile(output / "document.docx") as document:
        assert "word/document.xml" in document.namelist()
        assert any(name.startswith("word/media/") for name in document.namelist())
    run_checkov(output / "checkov-pass", "Enabled")
    run_checkov(output / "checkov-fail", "Suspended")
    print("Python diagrams, matplotlib/Pillow, document content and Checkov fixtures passed")


if __name__ == "__main__":
    main()
