#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

PROJECT="$1"
SCRIPT_DIR=$(dirname $0)
TEMPLATE_DIR="$SCRIPT_DIR/templates"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: Template directory '$TEMPLATE_DIR' not found."
  exit 1
fi

if [ -d "$PROJECT" ]; then
  echo "Error: directory '$PROJECT' already exists."
  exit 1
fi

mkdir -p "$PROJECT"

# Copy templates and replace placeholder
sed "s/__PROJECT_NAME__/$PROJECT/g" "$TEMPLATE_DIR/Makefile.template" > "$PROJECT/Makefile"
cp "$TEMPLATE_DIR/main.c.template" "$PROJECT/main.c"

echo "Created Arduino bare-metal project in '$PROJECT'"
echo "Next steps:"
echo "  cd $PROJECT"
echo "  make"
echo "  make upload"

