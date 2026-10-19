follow the below tutorial to install minikube on mac

https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Fx86-64%2Fstable%2Fbinary+download
1) Start minikube : ````minikube start --driver=docker````

2) Go to the downlaoded directory , and especially <blockquote>blue-green-individual</blockquote> folder and then type : ``kubectl apply -f ./blue `` this command will run all the yaml files in this folder

3) Check deployments : ``kubectl get deployments``

4) Check pods: ``kubectl get pods`` 

5) Check Services: ``kubectl get services ``

6) Then port forward (your service)

   ``kubectl port-forward service/deployment-demo 8080:80``

7)  Directly open on the browser by typing :``localhost:8080``

With setup-minikube.sh

If minikube had trouble starting last time, clean up first so it doesn’t hit the same leftover Docker network:

``minikube delete --all --purge``

``docker network rm minikube``
Goto--the folder where you downloaded the file  , keep the file in the minikubeprojects folders or what your you wish and run the below command in docker terminal 
cd ~/Downloads/minikubeprojects
chmod +x setup-minikube.sh
./setup-minikube.sh
