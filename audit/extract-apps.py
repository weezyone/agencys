"""Extract archive sources into ignored, workspace-local application directories."""
import json
import pathlib
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEST = ROOT / 'apps'
entries = []
for archive in ROOT.glob('*.zip'):
    app_id = archive.stem.replace(' (1)', '1')
    target = DEST / app_id
    with zipfile.ZipFile(archive) as source:
        for entry in source.infolist():
            path = pathlib.PurePosixPath(entry.filename)
            if path.is_absolute() or '..' in path.parts or any(':' in p for p in path.parts):
                raise ValueError('Unsafe archive path')
            if entry.is_dir() or any(p == '.git' or p.startswith('node_modules') for p in path.parts):
                continue
            output = target.joinpath(*path.parts)
            if output.exists():
                continue
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(source.read(entry))
    entries.append({'id': app_id, 'archive': archive.name, 'path': str(target.relative_to(ROOT))})
runtime = ROOT / 'audit' / 'runtime'
runtime.mkdir(exist_ok=True)
(runtime / 'extractions.json').write_text(json.dumps(entries, indent=2), encoding='utf-8')
print(f'Extracted {len(entries)} archives; existing files were preserved.')
