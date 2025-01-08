import { createContext, useEffect, useState } from 'react';
import PropTypes from 'prop-types'
import { Socket } from 'phoenix'

const PhoenixSocketContext = createContext<{ socket: Socket | null }>({ socket: null })

const PhoenixSocketProvider = ({ children }: { children: React.ReactNode }) => {
    const [socket, setSocket] = useState<Socket | null>(null);

    useEffect(() => {
        // TODO: make URL configurable
        const newSocket = new Socket('http://localhost:4000/socket');
        newSocket.connect();
        setSocket(newSocket);
    }, [])

    if (!socket) return null;

    return (
        <PhoenixSocketContext.Provider value={{ socket }}>{children}</PhoenixSocketContext.Provider>
    )
};

PhoenixSocketProvider.propTypes = {
    children: PropTypes.node,
}

export { PhoenixSocketContext, PhoenixSocketProvider }