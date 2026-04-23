FROM texlive/texlive:latest

# Install additional packages that might be needed
RUN apt-get update && apt-get install -y \
    ghostscript \
    python3-pygments \
    python3 \
    python3-pip \
    python3-yaml \
    && rm -rf /var/lib/apt/lists/*

# Verify Python and PyYAML installation
RUN python3 --version && python3 -c "import yaml; print('PyYAML installed successfully')"

# Set working directory
WORKDIR /workspace

# Default command
CMD ["pdflatex", "--version"]