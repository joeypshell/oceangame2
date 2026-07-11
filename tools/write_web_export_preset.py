import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRESET_PATH = ROOT / "export_presets.cfg"

MOBILE_VIEWPORT_HEAD = """<style id="oceangame-mobile-viewport">
html {
	width: 100%;
	height: 100%;
	overflow: hidden;
}

body {
	position: fixed;
	inset: 0;
	width: 100vw;
	height: 100vh;
	height: 100dvh;
}
</style>"""

PRESET_TEMPLATE = """[preset.0]

name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="*.json,*.png,*.svg,*.wav,*.ogg"
exclude_filter=""
export_path="exports/web/index.html"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include={head_include}
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/ensure_cross_origin_isolation_headers=false
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
"""


def main() -> None:
    preset = PRESET_TEMPLATE.format(head_include=json.dumps(MOBILE_VIEWPORT_HEAD))
    PRESET_PATH.write_text(preset, encoding="utf-8", newline="\n")
    print(f"Wrote {PRESET_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
