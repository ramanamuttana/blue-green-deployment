
1) start minikube : ````minikube start --driver=docker````

2) Go to the downlaoded directory , and especially <blockquote>blue-green-individual</blockquote> folder and then type : ``kubectl apply -f ./blue `` this command will run all the yaml files in this folder

3) Check deployments : ``kubectl get deployments``

4) Check pods: ``kubectl get pods`` 

5) Check Service``minikube service deployment-demo``

6)  Directly open on the browser by typing :``localhost:80``


