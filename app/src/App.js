import { useState } from 'react';
import { ethers } from 'ethers';
import { Button, Input } from 'semantic-ui-react';

import abi from './contracts/abi/ResolverKeeper.json';
import bytecode from './contracts/bytecode/ResolverKeeper.json';
import logo from './logo.svg';
import './App.css';
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

function App() {
  const [inputAsset, setInputAsset] = useState('');

  const deploy = async () => {
    factory = new ethers.ContractFactory(abi, bytecode, signer);
    contract = await factory.deploy();
    console.log(contract.address);
  }

  return (
    <div className="App">
      <header className="App-header">

      <Input
        size='large'
        placeholder='Asset...'
        value={inputAsset}
        onChange={e => setInputAsset(e.target.value)}
      />
      <Button
        onClick={() => deploy()}
      >
        Deploy
      </Button>
      </header>
    </div>
  );
}

export default App;
