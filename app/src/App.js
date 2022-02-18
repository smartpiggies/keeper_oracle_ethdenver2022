import { useState } from 'react';
import { ethers } from 'ethers';
import {
  Button,
  Container,
  Grid,
  Header,
  Input,
  Segment } from 'semantic-ui-react';

import resolverABI from './contracts/abi/ResolverKeeper.json';
import oracleABI from './contracts/abi/OracleKeeper.json';
import resolverBytecode from './contracts/bytecode/ResolverKeeper.json';
import oracleBytecode from './contracts/bytecode/OracleKeeper.json';
import { ORACLE_ADDRESS, SMARTPIGGIES } from './constants/constants';

let provider;
let signer;
let factory;

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
  const [oracle, setOracle] = useState('');
  const [price, setPrice] = useState('');
  const [tx, setTx] = useState('');
  const [txFull, setTxFull] = useState('');
  const [onChainAddress, setOnChainAddress] = useState('');
  const [resolverAddress, setResolverAddress] = useState('');

  const trimTx = (hash) => {
    let trim = `${hash.slice(0,5)}...${hash.slice(-4)}`
    return trim;
  }

  const deploy = async () => {
    factory = new ethers.ContractFactory(resolverABI, resolverBytecode, signer);
    let contract = await factory.deploy(SMARTPIGGIES, ORACLE_ADDRESS, 1000000);
    setResolver(contract);
    setResolverAddress(contract.address);
  }

  const register = async () => {
    setOracle(new ethers.Contract(ORACLE_ADDRESS, oracleABI, signer));
    let tx = await oracle.updateResolver(resolver.address, inputAsset);
    setTx(trimTx(tx.hash));
    setTxFull(tx.hash);
  }

  const setLookup = async () => {
    setOracle(new ethers.Contract(ORACLE_ADDRESS, oracleABI, signer));
    let tx = await oracle.setLookup(inputAsset, onChainAddress);
    setTx(trimTx(tx.hash));
    setTxFull(tx.hash);
  }

  const checkPrice = () => {
    setOracle(new ethers.Contract(ORACLE_ADDRESS, oracleABI, signer));
    oracle.getLatestPrice(inputAsset)
    .then(p => {
      setPrice(`
        ${p.toString().slice(0,-8)}.${p.div('1000000').toString().slice(-2)}
        `)
    });
  }
console.log(txFull)
  return (
    <Container style={{ marginTop: '3em', marginLeft: '30%' }}>
      <Header as='h1'>Oracle Creator</Header>
      {(tx == '') ?
        null :
        <a
          target='_blank'
          href={`https://kovan.etherscan.io/tx/${txFull}`}
        >
          <Header as='h5'>{tx}</Header>
        </a>
      }
      <Grid columns={3} stackable>
        <Grid.Column>
          <Header as='h3'>Deploy Resolver</Header>

          <Button
            onClick={deploy}
          >
            Deploy
          </Button>

          <Segment>
            {(resolverAddress == '') ?
              null:
              <Header as='h5'>{resolverAddress}</Header>
            }
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
            onClick={register}
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
            onChange={e => setOnChainAddress(e.target.value)}
          />
          <br></br>
          <Button
            onClick={setLookup}
          >
            Set
          </Button>

          <br></br>
          <br></br>
          <Header as='h3'>Check Asset Price</Header>
          <Button
            onClick={() => checkPrice()}
          >
            Check Price
          </Button>
          <br></br>
          {(price == '') ?
            null :
            price
          }
          <br></br>
          <br></br>
        </Grid.Column>
      </Grid>
    </Container>
  );
}

export default App;
