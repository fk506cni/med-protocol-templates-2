FROM texlive/texlive:latest

# Install additional packages including latexdiff
RUN apt-get update && apt-get install -y \
    ghostscript \
    python3-pygments \
    latexdiff \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Default command
CMD ["latexdiff", "--version"]