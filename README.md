# blue-green
blue-green deployment 

First we need to download the docker images 

```docker pull ramanamuttana/deployment-demo:blue```

```docker pull ramanamuttana/deployment-demo:green```

There  are two folders

1) blue-green-individual , Running the blue  and green deployments as an individuall(as two different versions.)

2) blue-green-together , Running blue-green deployment with two services but redirecting the traefik to the other services when one service is busy . 
