.PHONY: all clean run worker test

all: project1 project1.escript
	@chmod +x project1 project1.escript

clean:
	@rm -f *.beam *.dump

# Run standalone server (e.g. make run K=4)
run:
	./project1 $(or $(K), 4)

# Run worker connecting to server (e.g. make worker SERVER=10.3.43.194)
worker:
	@if [ -z "$(SERVER)" ]; then echo "Usage: make worker SERVER=<server_ip>"; exit 1; fi
	./project1 $(SERVER)

