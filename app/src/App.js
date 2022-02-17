import { useState } from 'react';
import { ethers } from 'ethers';
import {
  Button,
  Container,
  Grid,
  Header,
  Input } from 'semantic-ui-react';

import abi from './contracts/abi/ResolverKeeper.json';
import bytecode from './contracts/bytecode/ResolverKeeper.json';

let provider;
let signer;
let factory;
let contract;

async function init() {
    provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    // Prompt user for account connections
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    console.log("Account:", await signer.getAddress());
}

init();

const  App = () => {
  const [inputAsset, setInputAsset] = useState('');

  const deploy = async () => {
    factory = new ethers.ContractFactory(abi, bytecode, signer);
    contract = await factory.deploy();
    console.log(contract.address);
  }

  return (
    <Container style={{ marginTop: '3em', marginLeft: '30%' }}>
      <Header as='h1'>Oracle Creator</Header>
      <Grid columns={3} stackable>
        <Grid.Column>
          <Header as='h3'>Deploy</Header>

          <Input
            size='large'
            placeholder='Asset...'
            value={inputAsset}
            onChange={e => setInputAsset(e.target.value)}
          />
          <br></br>
          <Button
            onClick={() => deploy()}
          >
            Deploy
          </Button>
        </Grid.Column>
      </Grid>
    </Container>
  );
}

export default App;
