# blue-green
blue-green deployment 

First we need to download the docker images 

```docker pull ramanamuttana/deployment-demo:blue```

```docker pull ramanamuttana/deployment-demo:green```

There  are two folders

1) __blue-green-individual__ , Running the blue  and green deployments as an individuall(as two different versions.)

2) __blue-green-together__ , Running blue-green deployment with one service but redirecting the traefik to the other deployment when one is shutdown. 
