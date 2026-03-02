build "openclaw" {
  dockerfile = "Dockerfile"
}

secret "setup_password" {}

secret "openclaw_gateway_token" {
  generated = true
  length    = 64
}

service "gateway" {
  build   = build.openclaw
  command = "node src/server.js"

  endpoint {
    public = true
  }

  volume "data" {}

  env = {
    PORT                   = port
    SETUP_PASSWORD         = secret.setup_password
    OPENCLAW_GATEWAY_TOKEN = secret.openclaw_gateway_token
    OPENCLAW_STATE_DIR     = "${volume.data.path}/.openclaw"
    OPENCLAW_WORKSPACE_DIR = "${volume.data.path}/workspace"
  }

  dev {
    command = "docker build -t openclaw-template . && docker run --rm -p $PORT:$PORT -e PORT=$PORT -e SETUP_PASSWORD=$SETUP_PASSWORD -e OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN -e OPENCLAW_STATE_DIR=/data/.openclaw -e OPENCLAW_WORKSPACE_DIR=/data/workspace -v $(pwd)/.tmpdata:/data openclaw-template"
  }
}
