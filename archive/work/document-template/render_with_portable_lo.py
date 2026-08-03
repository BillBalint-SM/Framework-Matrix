import importlib.util
import subprocess
import sys
from pathlib import Path


WORKSPACE = Path(__file__).resolve().parents[2]
RENDER_SCRIPT = Path(
    r"C:\Users\littl\.codex\plugins\cache\openai-primary-runtime\documents\26.802.11031\skills\documents\render_docx.py"
)
SOFFICE = WORKSPACE / "work" / "runtime" / "libreoffice-26.2.5" / "program" / "soffice.com"


def load_renderer():
    spec = importlib.util.spec_from_file_location("codex_render_docx", RENDER_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load renderer: {RENDER_SCRIPT}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> None:
    if not SOFFICE.is_file():
        raise FileNotFoundError(f"Portable LibreOffice console launcher is missing: {SOFFICE}")

    renderer = load_renderer()
    original_run = subprocess.run

    def run_with_console_launcher(command, *args, **kwargs):
        explicit_command = list(command)
        if explicit_command and explicit_command[0] == "soffice":
            explicit_command[0] = str(SOFFICE)
        for index, value in enumerate(explicit_command):
            prefix = "-env:UserInstallation=file://"
            if isinstance(value, str) and value.startswith(prefix):
                windows_path = value[len(prefix) :]
                explicit_command[index] = "-env:UserInstallation=" + Path(windows_path).as_uri()
        return original_run(explicit_command, *args, **kwargs)

    renderer.subprocess.run = run_with_console_launcher
    renderer.main()


if __name__ == "__main__":
    main()
