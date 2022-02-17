import { useState } from 'react';
import { ethers } from 'ethers';
import {
  Button,
  Container,
  Grid,
  Header,
  Input,
  Segment } from 'semantic-ui-react';

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
  const [resolver, setResolver] = useState('');
  const [onChainAddress, setonChainAddress] = useState('');
  const [resolverAddress, setResolverAddress] = useState('');

  const deploy = async () => {
    factory = new ethers.ContractFactory(abi, bytecode, signer);
    //contract = await factory.deploy();
    setResolver(await factory.deploy());
    setResolverAddress(resolver.address);
    //console.log(contract.address);
    console.log(resolver.address);
  }

  const register = async () => {

    console.log();
  }

  const setLookup = async () => {
    
    console.log();
  }

  return (
    <Container style={{ marginTop: '3em', marginLeft: '30%' }}>
      <Header as='h1'>Oracle Creator</Header>
      <Grid columns={3} stackable>
        <Grid.Column>
          <Header as='h3'>Deploy Resolver</Header>

          <Button
            onClick={() => deploy()}
          >
            Deploy
          </Button>

          <Segment>
          {(resolverAddress == '') ?
            <Header as='h3'>{resolverAddress}</Header> :
            null}
          </Segment>

          <br></br>
          <Header as='h3'>Register Resolver</Header>

          <Input
            placeholder='Asset...'
            value={inputAsset}
            onChange={e => setInputAsset(e.target.value)}
          />
          <br></br>
          <Button
            onClick={() => deploy()}
          >
            Register
          </Button>

          <br></br>
          <br></br>
          <Header as='h3'>Set Reverse Lookup</Header>

          <Input
            placeholder='Asset...'
            value={inputAsset}
            onChange={e => setInputAsset(e.target.value)}
          />
          <br></br>
          <Input
            placeholder='Chainlink Address'
            value={onChainAddress}
            onChange={e => setonChainAddress(e.target.value)}
          />
          <br></br>
          <Button
            onClick={() => deploy()}
          >
            Set
          </Button>

        </Grid.Column>
      </Grid>
    </Container>
  );
}

export default App;
