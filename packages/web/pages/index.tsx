import Head from 'next/head'
import Image from 'next/image'
import styles from '../styles/Home.module.css'
import { ConnectButton } from '@web3uikit/web3'

export default function Home() {
  return (
    <div>
      <h1 className='text-3xl font-bold underline'>Task Vault</h1>
      <ConnectButton />
    </div>
  )
}
