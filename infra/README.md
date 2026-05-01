# skill-test-infra

Este es el infra montado con Terraform. Los objetos relevantes aquí son:
  - KMS
  - CloudHSM
  - S3

EL EC2 lo he creado como bastion para poder gestional el cluster de CloudHSM. Obviamente necesitaba una VPC también.

---

Sé que el enunciado dice que es una cuenta dedicada para las keys, pero por simplicidad, lo he creado todo en la misma account.
  - Aquí cambiarían las policy de IAM para poder acceder a un objeto de otra cuenta, pero no es nada de otro mundo.
También, por simplicidad, he acotado los objetos de DynamoDB, RDS y S3 a sólo S3, porque es el más barato.
  - Tampoco habría ningún problema con aplicar los mismos principios a una base de datos.

Lo que hace esta demo, es 
  - Crear una key externa en KMS
  - Generar el import token y el public key para envolver el key material de CloudHSM y transportarlo de forma segura por internet.
    - En este caso las dos entidades están en la misma account, pero si no lo fueran, la transportación de la key sería de forma segura.
<img width="1920" height="1080" alt="Screenshot from 2026-03-03 12-26-31" src="https://github.com/user-attachments/assets/b3a3eb87-b393-4f15-b45b-d4874c399e89" />

En el screenshot de arriba, se puede ver que al principio (una vez hemos desplegado la infraestructura con Terraform), tenemos una Key externa que necesita que se importe la key material (la key con el cual se cifrarán los datos).
Este proceso se hace en un pipeline de GitLab, que se encarga de:
  - Extraer el ImportToken y PublicKey para envolver la key material y transportarlo a KMS
  - Codificarlos a binario
  - Envolver/cifrar la key material
  - Transportarlo a KMS
  - Hacer un pequeño test en S3 para asegurarnos que la key funciona.
    
<img width="1401" height="797" alt="Screenshot 2026-03-03 at 13-30-59 Pipeline #74 · Administrator _ task1 · GitLab" src="https://github.com/user-attachments/assets/0160b76b-b433-4109-bd46-0af3f135e527" />

Una vez el pipeline se acaba, se debería de ver que la Key ya está disponible para el uso (tiene la key material asociada)

<img width="1610" height="789" alt="Screenshot 2026-03-03 at 12-38-55 Key Management Service us-east-2" src="https://github.com/user-attachments/assets/1ef1d1cd-e341-488b-933b-464a1619e35f" />

Tambié se puede ver que en el job de test, se ha generado un fichero de texto y se ha subido a S3, y que ese fichero está siendo encriptado con la key que hemos importado.

<img width="1710" height="1495" alt="Screenshot 2026-03-03 at 12-42-20 quotes_quote-5649691a txt - Object in S3 bucket bucket-cgicom-task1-dev-us-east-2 S3 us-east-2" src="https://github.com/user-attachments/assets/1a1467a0-0c19-41b8-831d-dbc59fcd055e" />

---

Respondiendo a las preguntas del test:

Q: What are the main challenges to apply key rotation? and what impacts you can identify?
A: The main challenge I see here is the handling exteral key without compromising it. The
   impact can be unusable data if the rotation doesn´t go through.

Q: From your respective, what are the steps of applying key rotation (high level description)
- generate the key
- securely bring it to aws
- add the new key
- ensure the functionality of the new key
- remove the old key


Q: After applying the rotation on keys, we’re required to have a
   monitoring on the resources to identify - at any given time -
   resources (rds, dynamodb, S3) that are not complaints
   (resources where rotation is not applied) how could we
   achieve this requirement with AN aws managed services?
A: Since this is not an AWS managed key, it is not possible to monitor
   the rotation of the key, but what I would do is to monitor the resources
   that consume that key. Inc ase the key rotation was not successful, there
   should be lots of errors decrypting the data.

Q: What’s the best way to secure key material during their transportation from HSM to AWS KMS?
A: The way I did in this demo is one of the best ways to transport a key material (described above).
   While I was implementing this solution, I relised that KMS has a native key store for CloudHSM.
   If there would be a solution for an external HSM, migh be even better solution than the one I provided.
   
<img width="1899" height="372" alt="Screenshot 2026-03-03 at 13-46-41 AWS CloudHSM key stores KMS Console" src="https://github.com/user-attachments/assets/29507fe6-3070-4f25-a8a7-386ae08f6721" />

   


