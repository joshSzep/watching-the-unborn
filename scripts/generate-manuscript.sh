#!/bin/bash

# Generate manuscript from chapter files
# Outputs MANUSCRIPT.md in the repository root

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHAPTERS_DIR="$REPO_ROOT/chapters"
OUTPUT_FILE="$REPO_ROOT/MANUSCRIPT.md"

# Start with title and author
cat > "$OUTPUT_FILE" << 'EOF'
# Watching the Unborn

*Joshua Szepietowski*

EOF

# Process each part in order
for part_num in 1 2 3; do
    # Find the part folder
    part_folder=$(find "$CHAPTERS_DIR" -maxdepth 1 -type d -name "Part $part_num - *" | head -1)
    
    if [[ -z "$part_folder" ]]; then
        echo "Warning: Part $part_num folder not found" >&2
        continue
    fi
    
    # Extract part name from folder
    part_name=$(basename "$part_folder")
    
    # Write part heading
    echo "## $part_name" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Process chapters in order
    find "$part_folder" -name "Chapter *.md" -type f | sort | while read -r chapter_file; do
        # Extract chapter name from filename (without .md extension)
        chapter_name=$(basename "$chapter_file" .md)
        
        # Write chapter heading
        echo "### $chapter_name" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Get chapter contents, skipping the first line (which is the chapter's own heading)
        tail -n +2 "$chapter_file" >> "$OUTPUT_FILE"
        
        # Add spacing between chapters
        echo "" >> "$OUTPUT_FILE"
        echo "---" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done
done

echo "Manuscript generated: $OUTPUT_FILE"
