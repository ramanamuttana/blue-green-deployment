# blue-green
## Getting Started

This project demonstrates blue-green deployment strategies using Docker and Kubernetes. Blue-green deployment is a technique that reduces downtime and risk by running two identical production environments.

### Prerequisites

- Docker installed and running
- Kubernetes cluster (minikube for local testing)
- kubectl command-line tool
- Basic knowledge of Docker and Kubernetes
blue-green deployment 

First we need to download the docker images 

```docker pull ramanamuttana/deployment-demo:blue```

```docker pull ramanamuttana/deployment-demo:green```

After docker images downlaoded then downlaod or clone this repo , Here there  are two folders

1) __blue-green-individual__ , Running the blue  and green deployments as an individuall(as two different versions.)

2) __blue-green-together__ , Running blue-green deployment with one service but redirecting the traefik to the other deployment when one is shutdown. 



### Features

- **Zero-downtime deployments**: Switch between versions without service interruption
- **Rollback capability**: Quickly revert to the previous version if issues arise
- **Service routing**: Uses Traefik for intelligent traffic routing between blue and green deployments

### Usage Instructions

For detailed instructions on running each deployment strategy, please refer to the respective README files in the subdirectories:
- `blue-green-individual/README.md` for running individual deployments
- `blue-green-together/README.md` for running synchronized deployments with traffic switching

### Support

For issues or questions, please open an issue in the repository.
