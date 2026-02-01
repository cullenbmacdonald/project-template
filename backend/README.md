# Backend

Customize this directory for your tech stack.

## Go (default)

```bash
# Initialize module
go mod init your-module-name

# Create cmd/server/main.go
mkdir -p cmd/server
```

## Python

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install fastapi uvicorn
pip freeze > requirements.txt
```

## Node.js

```bash
npm init -y
npm install express
```

## Makefile

The Makefile has targets for common operations. Customize the commands for your stack:

- `make fmt` - Format code
- `make lint` - Run linter
- `make test` - Run tests
- `make build` - Build binary/bundle
- `make run` - Run the application
