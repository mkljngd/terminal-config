# IPython (also used by `python manage.py shell` / djshell when installed).
from IPython.utils.PyColorize import Theme, theme_table
from pygments.token import Token

c = get_config()  # noqa: F821

# Full 24-bit color (WezTerm supports it) instead of the 256-color fallback.
c.TerminalInteractiveShell.true_color = True

# Terminal theme: Pygments' nord for code, with the prompt, tracebacks and
# output in the terminal's cyan / magenta colors. IPython 9 ignores
# highlighting_style, so the theme is registered and selected via `colors`.
CYAN, CYAN_BRIGHT, CYAN_PALE = "#0abdc6", "#2dd4bf", "#99f6e4"
AMBER, AMBER_LIGHT, RED, DIM = "#ff00ff", "#f472b6", "#db2777", "#475569"

theme_table["terminal"] = Theme(
    "terminal",
    "nord",
    {
        Token.Prompt: CYAN,
        Token.PromptNum: f"{CYAN_BRIGHT} bold",
        Token.OutPrompt: AMBER,
        Token.OutPromptNum: f"{AMBER_LIGHT} bold",
        Token.Lineno: DIM,
        Token.LinenoEm: f"{CYAN_BRIGHT} bold",
        Token.ValEm: f"{AMBER} bold",
        Token.VName: "#0abdc6",
        Token.Caret: "",
        Token.Filename: CYAN_PALE,
        Token.FilenameEm: f"{CYAN_PALE} bold",
        Token.ExcName: f"{RED} bold",
        Token.Topline: "#27272a",
        Token.Breakpoint.Enabled: RED,
        Token.Breakpoint.Disabled: DIM,
        Token.TbHighlight: "bg:#0b3d5e",
    },
)
c.InteractiveShell.colors = "terminal"

# No startup tip line.
c.TerminalInteractiveShell.banner2 = ""
