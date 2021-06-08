# Jasper Report Files + Database Scripts
Database scripts for the Database behind the Rhomicom ERP System as well as sample Jasper Studio Report Designs (jrxmls)

docker exec -it rho-pgadmin sh 
docker exec -it rho-pgadmin sh -c "cd /var/lib/pgadmin/storage/info_rhomicom.com/ && psql -h rho-pgdb -U postgres"
psql -h rho-pgdb -p 5432 -U postgres -v -d tacmsapi < makerzgroup_tac.sql


