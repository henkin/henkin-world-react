import { GetServerSidePropsContext } from 'next';
import { serverSideTranslations } from 'next-i18next/serverSideTranslations';
import type { NextPageWithLayout } from 'types';
import { useTranslation } from 'next-i18next';
import Link from 'next/link';
import { useRouter } from 'next/router';

const Products: NextPageWithLayout = () => {
  const { t } = useTranslation('common');
  const router = useRouter();

  return (
    <div className="p-3">
      <ul className="list-disc pl-5">
        <li>
          <Link href={`/teams/${router.query.slug}/inbox`} className="text-blue-500 hover:underline">
            {t('inbox')}
          </Link>
        </li>
      </ul>
    </div>
  );
};

export async function getServerSideProps({
  locale,
}: GetServerSidePropsContext) {
  return {
    props: {
      ...(locale ? await serverSideTranslations(locale, ['common']) : {}),
    },
  };
}

export default Products;
