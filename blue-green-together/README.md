1) start minikube : ``minikube start --driver=docker``

2) Go tot he downloaded directory , and especially blue-green-together folder and then type : ``kubectl apply -f ./blue``

3) Go tot he downloaded directory , and especially blue-green-together folder and then type : ``kubectl apply -f ./green``


4) Start with Blue ,Go to the downlaoded directory , and especially blue-green-together folder and then type : ``kubectl apply -f ./service-blue-green``

5) Check deployments : ``kubectl get deployments``

6) Check pods: ``kubectl get pods``

7) Do Port forwarding : ``kubectl port-forward service/deployment-demo 8080:80``

8) directly type ``localhost:80`` or ``localhost:8080`` --> it will redirects to ``localhost:80`` or follow below commands 

9)  Directly open on the browser by typing : ``minikube service deployment-demo`` or ``minikube service deployment-demo-green``

10)  Close the terminal that running the port forwarding and do the changes to the ``service .yaml`` and re run the service and port forwarding, check ``service-blue-green`` folder. 
