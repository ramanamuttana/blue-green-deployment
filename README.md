# blue-green
blue-green deployment 

First download the docker images 

```docker pull ramanamuttana/deployment-demo:blue```

```docker pull ramanamuttana/deployment-demo:green```

There  are two folders

1) blue-green-individual , Running blue deployment and green deployment individually with two different services.

2) blue-green-together , Running blue-green deployment with two services but redirecting the traefik to the other services when one service is busy . 
