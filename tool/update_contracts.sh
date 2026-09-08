#!/usr/bin/env bash
# تحديثٌ عمديٌّ للقطات العقد في contracts/ — لا يُشغَّل ضمن بناءٍ عادي.
#
# الاستعمال:
#   tool/update_contracts.sh /path/to/lynomia-hub [https://host]
#
# المعامل الأول: نسخة عمل للواجهة الخلفية (مقروءة فقط — لا يعدَّل فيها شيء).
# المعامل الثاني (اختياري): مضيف يخدم /api/mobile/v1/openapi.json لالتقاط
# لقطة المواصفة الحية. بدونه تُحدَّث لقطة القدرات ومصدر العقد فقط.
set -euo pipefail

BACKEND="${1:?مسار مستودع lynomia-hub مطلوب}"
HOST="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

SHA="$(git -C "$BACKEND" rev-parse HEAD)"
REF="$(git -C "$BACKEND" rev-parse --abbrev-ref HEAD)"
BACKEND_VERSION="$(cat "$BACKEND/VERSION" 2>/dev/null || echo unknown)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cp "$BACKEND/docs/mobile-readiness/mobile-capabilities.json" "$ROOT/contracts/mobile-capabilities.json"
SCHEMA_VERSION="$(python3 -c "import json;print(json.load(open('$ROOT/contracts/mobile-capabilities.json'))['schema_version'])")"

if [ -n "$HOST" ]; then
  curl -fsS "$HOST/api/mobile/v1/openapi.json" -o "$ROOT/contracts/mobile-openapi.json"
  echo "✔ mobile-openapi.json حُدِّثت من $HOST"
fi

python3 - "$ROOT/contracts/backend-source.json" <<PY
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d.update({
    "backend_ref": "$REF",
    "backend_commit_sha": "$SHA",
    "backend_version": "$BACKEND_VERSION",
    "schema_version": "$SCHEMA_VERSION",
    "snapshot_taken_at": "$NOW",
})
d.pop("note", None)
json.dump(d, open(p, "w"), ensure_ascii=False, indent=2)
open(p, "a").write("\n")
PY

echo "✔ اللقطات حُدِّثت إلى $REF@$SHA — راجع git diff لرؤية الانحراف، وشغّل flutter test لاختبارات العقد."
