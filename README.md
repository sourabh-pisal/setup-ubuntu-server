# setup ubuntu server
Repository to setup a new Ubuntu server machine

## Installation
To install the configuration run the following command:

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sourabh-pisal/setup-ubuntu-server/main/install.sh)"
```

To install without AWS CLI:

```
bash <(curl -fsSL https://raw.githubusercontent.com/sourabh-pisal/setup-ubuntu-server/main/install.sh) --skip-aws-cli
```

To install without Tailscale:

```
bash <(curl -fsSL https://raw.githubusercontent.com/sourabh-pisal/setup-ubuntu-server/main/install.sh) --skip-tailscale
```

To install without Docker:

```
bash <(curl -fsSL https://raw.githubusercontent.com/sourabh-pisal/setup-ubuntu-server/main/install.sh) --skip-docker
```

Flags can be combined:

```
bash <(curl -fsSL https://raw.githubusercontent.com/sourabh-pisal/setup-ubuntu-server/main/install.sh) --skip-aws-cli --skip-tailscale --skip-docker
```
