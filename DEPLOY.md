# Deployment Guide

## Step 1: Create GitHub Repository

1. Go to GitHub and create a new repository called `spiral`
2. Make it public
3. Don't initialize with README (you already have one)

## Step 2: Push Your Code

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .
git commit -m "Initial spiral implementation"

# Add your GitHub repo as origin
git remote add origin https://github.com/YOURUSERNAME/spiral.git

# Push to main branch
git branch -M main
git push -u origin main
```

## Step 3: Create Your First Release

```bash
# Create and push a tag to trigger the release workflow
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Actions workflow will automatically:
- Build binaries for macOS (Intel + Apple Silicon), Linux, and Windows
- Create a release with all binaries attached
- Generate release notes

## Step 4: Update README with Correct URL

Replace `yourusername` in README.md with your actual GitHub username:

```bash
# Find and replace in README.md
sed -i '' 's/yourusername/YOURACTUALUSERNAME/g' README.md
git add README.md
git commit -m "Update install URLs with correct username"
git push
```

## Step 5: Test Installation

Once the release is live, test the installation:

```bash
# Download and test
curl -L https://github.com/YOURUSERNAME/spiral/releases/latest/download/spiral-darwin-arm64 -o spiral-test
chmod +x spiral-test
./spiral-test show all
```

## What Users Will See

After you push a tag, users can install with:

```bash
curl -L https://github.com/YOURUSERNAME/spiral/releases/latest/download/spiral-darwin-arm64 -o spiral
chmod +x spiral
sudo mv spiral /usr/local/bin/
spiral show all  # Start using immediately
```

## Updating Releases

For future updates:
1. Make your changes
2. Commit and push
3. Create a new tag: `git tag v1.0.1 && git push origin v1.0.1`
4. GitHub Actions will automatically build and release

The release workflow is already set up in `.github/workflows/release.yml` 