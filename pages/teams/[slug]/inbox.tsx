import AppShell from '@/components/shared/shell/AppShell'
import { useSession } from 'next-auth/react'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import type { NextPageWithLayout } from 'types'
import { useTranslation } from 'next-i18next'
import { GetServerSidePropsContext } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'

// Authenticated Inbox page
const Inbox: NextPageWithLayout = () => {
  const { status } = useSession()
  const router = useRouter()
  const { t } = useTranslation('common')

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/auth/login')
    }
  }, [status, router])

  if (status !== 'authenticated') {
    return null
  }

  return <div>{t('hello-inbox')}</div>
}

Inbox.getLayout = function getLayout(page) {
  return <AppShell>{page}</AppShell>
}

export async function getServerSideProps({ locale }: GetServerSidePropsContext) {
  return {
    props: {
      ...(locale ? await serverSideTranslations(locale, ['common']) : {}),
    },
  }
}

export default Inbox 