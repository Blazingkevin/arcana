import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Arcana Protocol',
  description: 'ZK Credentials + Stealth Addresses on Starknet',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
