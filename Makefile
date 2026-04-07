.PHONY: build up down logs shell

# Avvia lo script di start che recupera i dati da Terragrunt e lancia Docker
up:
	bash ./start.sh

# Spegne tutto
down:
	docker compose down

# Ricostruisce le immagini (da fare se cambi il codice Go)
build:
	docker compose build

# Guarda i log in tempo reale
logs:
	docker compose logs -f

# Pulisce i volumi (cancella le root scaricate e la lista log)
clean:
	docker compose down -v
	rm -f scripts/setup_done
