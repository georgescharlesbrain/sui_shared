import { useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Link } from 'react-router-dom';
import { linkToExplorer } from '@polymedia/webutils';

import { AppContext } from './App';

export const Home: React.FC = () =>
{
    useEffect(() => {
        document.title = 'Polymedia Profile - Home';
    }, []);

    const { network, profileManager } = useOutletContext<AppContext>();


    return <div id='page' className='page-home'>
        <h1>
            HOME
        </h1>
        <p>
            Polymedia Profile is a fully on-chain profile system on <a href='https://sui.io' target='_blank' rel='noopener'>Sui</a>. It lets users attach a profile (name, picture, etc) to their Sui address. Over 137,000 profiles have been created to date.
            <br/>
            <br/>

            This web app lets users manage their profiles on the default registry, called <i><a href={linkToExplorer(network, 'object', profileManager.registryId)} target='_blank' rel='noopener'>polymedia-main</a></i>.
            <br/>
            <br/>
            The code is fully <a href='https://github.com/juzybits/polymedia-profile' target='_blank' rel='noopener'>open-source</a>, and there is a <a href='https://www.npmjs.com/package/@polymedia/profile-sdk' target='_blank' rel='noopener'>TypeScript SDK</a> to facilitate 3rd party integrations.
        </p>
        <Link to='/manage' className='btn' style={{marginRight: '0.5em'}}>MANAGE PROFILE</Link>
        <Link to='/docs' className='btn'>READ DOCS</Link>
    </div>;
}
