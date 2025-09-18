# SpringBoot API Docker templeate

## Run project w/o Docker Compose
### Rebuild Image
```docker build -t spring-api-image:latest .```
### Execute container
```docker run --name spring-api-container -p 8080:8080 -d spring-api-image:latest```

## Run project with Docker Compose
```docker compose -p spring-api-container up --build -d```

### Delete container
```docker compose -p spring-api-container down```

### Delete container and volumes
```docker compose -p spring-api-container down -v```

### Check env variables loaded correctly
```docker exec -it <nombre-container> printenv SPRING_PROFILES_ACTIVE```