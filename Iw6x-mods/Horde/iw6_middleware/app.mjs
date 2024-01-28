import express from 'express';

const app = express();
const port = 4000;

app.get('/account/deposit', async (req, res) => { //req.params.xuid
    let deposit;
    const
        account = await fetch_account( req.query.xuid ), 
        amount = parseInt(req.query.amount);
        
        if(account.length < 1 && !isNaN(amount) && amount >= 0) 
            deposit = await create_account( req.query.xuid, amount );
        else if(!isNaN(amount) && amount >= 0) {
            deposit = amount;
            await update_account( req.query.xuid, account.balance + amount );
        }
        else
            deposit = 0;

    res.send( deposit.toString() );
});

app.get('/account/withdraw', async (req, res) => {
    let withdraw;
    const 
        account = await fetch_account( req.query.xuid ), 
        amount = parseInt(req.query.amount) || Number.MAX_VALUE;
    
    if( account.length < 1 || isNaN(amount) || amount < 0 ) 
        withdraw = 0;
    else {
        if( amount < account.balance ) {
            withdraw = amount;
            await update_account( req.query.xuid, account.balance - amount);
        }
        else { // withdraw all
            withdraw = account.balance;
            await update_account( req.query.xuid, 0);
        }
    }

    res.send( withdraw.toString() );
});


async function fetch_account( xuid ) 
{
    try {
        const response = await fetch(`http://localhost:3000/accounts/${xuid}`, {method: 'GET'});
        const data = await response.json();
        return data;
    } catch (error) {
        return [];
        //console.log('error', error);
    }
}

async function create_account( xuid, amount ) 
{
    try {
        await fetch(`http://localhost:3000/accounts`, {
        method: 'POST',
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({id: xuid, balance: amount})
        });
        return amount;
    } catch (error) {
        console.log('error', error);
    }
}

async function update_account( xuid, new_total ) 
{
    try {
        await fetch(`http://localhost:3000/accounts/${xuid}`, {
        method: 'PUT',
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify( {"balance": new_total} )
        });
        return new_total;
    } catch (error) {
        console.log('error', error);
    }
}

app.listen(port, () => console.log(port) );

// http://localhost:4000/account/withdraw/?xuid=0&amount=100
// http://localhost:4000/account/deposit/?xuid=0&amount=100