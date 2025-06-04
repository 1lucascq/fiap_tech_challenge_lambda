const AWS = require('aws-sdk');
const { Client } = require('pg');

exports.handler = async (event) => {
    try {
        const body = JSON.parse(event.body);
        const cpf = body.cpf;

        if (!cpf) {
            return {
                statusCode: 400,
                body: JSON.stringify({ message: 'CPF é obrigatório.' }),
            };
        }

        const userExists = await checkCPFInDatabase(cpf);
        
        if (userExists) {
            const token = generateSimpleToken(cpf);
            
            return {
                statusCode: 200,
                body: JSON.stringify({
                    token: token,
                    authorized: true
                }),
            };
        } else {
            return {
                statusCode: 401,
                body: JSON.stringify({
                    message: 'Not found.',
                    authorized: false
                }),
            };
        }

    } catch (error) {
        console.error('Erro:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Internal Server Error.' }),
        };
    }
};

async function checkCPFInDatabase(cpf) {
    try {
        const client = new Client({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            port: process.env.DB_PORT || 5432,
            ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
        });
        
        await client.connect();
        
        const result = await client.query(
            'SELECT id FROM users WHERE cpf = $1',
            [cpf]
        );
        
        await client.end();
        return result.rows.length > 0;
        
    } catch (error) {
        console.error('Database error:', error);
        return false;
    }
}

function generateSimpleToken(cpf) {
    const payload = {
        cpf: cpf,
        timestamp: Date.now(),
        authorized: true
    };
    
    return JSON.stringify(payload);
}