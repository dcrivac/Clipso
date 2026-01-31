#!/bin/bash

# Clipso Release Script
# Automates the complete release process: GitHub release + website update

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WEBSITE_FILE="website/index.html"
GITHUB_REPO="dcrivac/Clipso"

# Helper functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}Clipso Release Manager${NC}                              ${BLUE}║${NC}"
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}\n"
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Get current version from latest tag
get_current_version() {
    local version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "${version#v}"  # Remove 'v' prefix
}

# Parse semantic version
parse_version() {
    local version=$1
    IFS='.' read -r -a parts <<< "$version"
    echo "${parts[0]}" "${parts[1]}" "${parts[2]}"
}

# Increment version
increment_version() {
    local current=$1
    local bump_type=$2

    read -r major minor patch <<< $(parse_version "$current")

    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "$current"
            return
            ;;
    esac

    echo "$major.$minor.$patch"
}

# Check if git repo is clean
check_git_status() {
    if [[ -n $(git status -s) ]]; then
        print_error "Git working directory is not clean. Please commit or stash changes first."
        echo ""
        git status -s
        exit 1
    fi
    print_success "Git working directory is clean"
}

# Update website download links
update_website() {
    local old_version=$1
    local new_version=$2

    print_step "Updating website download links..."

    if [[ ! -f "$WEBSITE_FILE" ]]; then
        print_error "Website file not found: $WEBSITE_FILE"
        return 1
    fi

    # Backup original file
    cp "$WEBSITE_FILE" "$WEBSITE_FILE.backup"

    # Update all download links
    sed -i '' "s|releases/download/v${old_version}/Clipso-${old_version}|releases/download/v${new_version}/Clipso-${new_version}|g" "$WEBSITE_FILE"

    # Count replacements
    local count=$(grep -c "releases/download/v${new_version}/Clipso-${new_version}" "$WEBSITE_FILE" || true)

    if [[ $count -gt 0 ]]; then
        print_success "Updated $count download links in $WEBSITE_FILE"
        rm "$WEBSITE_FILE.backup"
        return 0
    else
        print_warning "No download links were updated. Restoring backup."
        mv "$WEBSITE_FILE.backup" "$WEBSITE_FILE"
        return 1
    fi
}

# Create release notes template
create_release_notes() {
    local version=$1
    local notes_file="RELEASE_v${version}.md"

    if [[ -f "$notes_file" ]]; then
        print_success "Release notes already exist: $notes_file"
        return 0
    fi

    cat > "$notes_file" <<EOF
# Clipso v${version}

## What's New

- Feature 1
- Feature 2

## Improvements

- Improvement 1
- Improvement 2

## Bug Fixes

- Fix 1
- Fix 2

## Breaking Changes

- None

## Notes

- Thank you to all contributors!

---

**Full Changelog**: https://github.com/${GITHUB_REPO}/compare/v...v${version}
EOF

    print_success "Created release notes template: $notes_file"
    print_warning "Please edit $notes_file before continuing"
}

# Main release flow
main() {
    print_header

    # Parse command line arguments
    local version_arg=""
    local auto_yes=false
    local skip_checks=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --version|-v)
                version_arg="$2"
                shift 2
                ;;
            --yes|-y)
                auto_yes=true
                shift
                ;;
            --skip-checks)
                skip_checks=true
                shift
                ;;
            --help|-h)
                cat <<EOF
Usage: ./release.sh [OPTIONS]

Options:
    -v, --version VERSION    Specify version number (e.g., 1.0.4)
    -y, --yes               Auto-confirm all prompts
    --skip-checks           Skip git status checks (not recommended)
    -h, --help              Show this help message

Interactive Mode (default):
    ./release.sh

    Prompts for version bump type (major/minor/patch) or custom version

Examples:
    ./release.sh                    # Interactive mode
    ./release.sh -v 1.0.4           # Release version 1.0.4
    ./release.sh -v 1.0.4 -y        # Auto-confirm

Version Bumping:
    major: 1.0.0 → 2.0.0
    minor: 1.0.0 → 1.1.0
    patch: 1.0.0 → 1.0.1
EOF
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Step 1: Check git status
    if [[ "$skip_checks" == false ]]; then
        print_step "Checking git status..."
        check_git_status
    fi

    # Step 2: Determine version
    local current_version=$(get_current_version)
    print_step "Current version: v${current_version}"

    local new_version=""

    if [[ -n "$version_arg" ]]; then
        new_version="$version_arg"
        print_step "Target version: v${new_version}"
    else
        # Interactive version selection
        echo ""
        echo "Select version bump type:"
        echo "  1) Major (${current_version} → $(increment_version $current_version major))"
        echo "  2) Minor (${current_version} → $(increment_version $current_version minor))"
        echo "  3) Patch (${current_version} → $(increment_version $current_version patch))"
        echo "  4) Custom"
        echo ""
        read -p "Choice [1-4]: " choice

        case $choice in
            1)
                new_version=$(increment_version $current_version major)
                ;;
            2)
                new_version=$(increment_version $current_version minor)
                ;;
            3)
                new_version=$(increment_version $current_version patch)
                ;;
            4)
                read -p "Enter custom version (e.g., 1.0.4): " new_version
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    fi

    # Validate version format
    if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $new_version (expected: X.Y.Z)"
        exit 1
    fi

    print_success "New version: v${new_version}"

    # Step 3: Confirmation
    if [[ "$auto_yes" == false ]]; then
        echo ""
        echo -e "${YELLOW}This will:${NC}"
        echo "  1. Update website download links (v${current_version} → v${new_version})"
        echo "  2. Commit website changes"
        echo "  3. Create and push git tag v${new_version}"
        echo "  4. Trigger GitHub Actions release workflow"
        echo ""
        read -p "Continue? [y/N]: " confirm

        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warning "Release cancelled"
            exit 0
        fi
    fi

    # Step 4: Create release notes template
    echo ""
    print_step "Checking release notes..."
    create_release_notes "$new_version"

    local notes_file="RELEASE_v${new_version}.md"
    if [[ -f "$notes_file" ]]; then
        if [[ "$auto_yes" == false ]]; then
            read -p "Edit release notes now? [y/N]: " edit_notes
            if [[ "$edit_notes" =~ ^[Yy]$ ]]; then
                ${EDITOR:-nano} "$notes_file"
            fi
        fi
    fi

    # Step 5: Update website
    echo ""
    print_step "Updating website..."
    if update_website "$current_version" "$new_version"; then
        print_success "Website updated successfully"
    else
        print_error "Failed to update website"
        exit 1
    fi

    # Step 6: Commit website changes
    echo ""
    print_step "Committing website changes..."
    git add "$WEBSITE_FILE"

    if [[ -f "$notes_file" ]]; then
        git add "$notes_file"
    fi

    git commit -m "Release v${new_version}: Update download links"
    print_success "Changes committed"

    # Step 7: Create and push tag
    echo ""
    print_step "Creating git tag v${new_version}..."
    git tag -a "v${new_version}" -m "Release v${new_version}"
    print_success "Tag created"

    print_step "Pushing changes and tag to GitHub..."
    git push origin main
    git push origin "v${new_version}"
    print_success "Pushed to GitHub"

    # Step 8: Success message
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${GREEN}✓ Release v${new_version} initiated successfully!${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Monitor GitHub Actions workflow:"
    echo "     https://github.com/${GITHUB_REPO}/actions"
    echo ""
    echo "  2. Once complete, verify the release:"
    echo "     https://github.com/${GITHUB_REPO}/releases/tag/v${new_version}"
    echo ""
    echo "  3. Test the download link:"
    echo "     https://github.com/${GITHUB_REPO}/releases/download/v${new_version}/Clipso-${new_version}.dmg"
    echo ""
    echo -e "${BLUE}Website will be updated automatically via GitHub Pages.${NC}"
    echo ""
}

# Run main function
main "$@"
