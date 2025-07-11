# Rinha de Backend - 2025 D Implementation

This project is a backend application developed in the D programming language for the Rinha de Backend 2025 challenge. The main goal is to create a solution that integrates with payment processors to handle payment requests efficiently.

## Project Structure

The project is organized as follows:

```
rinha-de-backend-2025-d
├── source
│   ├── app.d                # Entry point of the application
│   ├── handlers
│   │   ├── payments.d       # Handles payment requests
│   │   └── summary.d        # Handles payment summaries
│   └── services
│       └── payment_processor.d # Interacts with payment processor APIs
├── docker-compose.yml        # Defines Docker services and configurations
├── Dockerfile                 # Instructions to build the Docker image
├── dub.json                  # DUB package manager configuration
└── README.md                 # Project documentation
```

## Setup Instructions

1. **Clone the Repository**
   Clone this repository to your local machine using:
   ```
   git clone <repository-url>
   ```

2. **Install DUB**
   Ensure you have DUB installed. You can find installation instructions at [DUB's official website](https://dub.pm/).

3. **Build the Project**
   Navigate to the project directory and run:
   ```
   dub build
   ```

4. **Run the Application**
   You can run the application using:
   ```
   dub run
   ```

5. **Docker Setup**
   To run the application in a Docker container, use the following command:
   ```
   docker-compose up --build
   ```

## Usage

The application exposes the following endpoints:

- **POST /payments**: Processes payment requests.
- **GET /payments-summary**: Retrieves a summary of processed payments.

## Implementation Details

- The application is designed to handle payment requests asynchronously, ensuring that it can process multiple requests efficiently.
- It integrates with two payment processors: a default processor with lower fees and a fallback processor for reliability.
- Health checks are implemented to monitor the status of the payment processors.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.