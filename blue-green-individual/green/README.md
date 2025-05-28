1) start minikube : ``minikube start --driver=docker``

2) Go tot he downlaoded directory , and especially <blockquote>blue-green-individual</blockquote> folder and then type : ``kubectl apply -f ./green``

3) Check deployments : ``kubectl get deployments``

4) Check pods: ``kubectl get pods ``

5) Directly open on the browser by typing :``minikube service deployment-demo-green``

6) directly type ``localhost:8080 ``
   
    Explanation: we can chnage the port number incase  needed , this can be done in service-green.yaml
