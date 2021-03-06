package com.serotonin.m2m2.rt.serial;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.serotonin.io.serial.SerialPortException;
import com.serotonin.io.serial.SerialPortInputStream;
import com.serotonin.io.serial.SerialPortOutputStream;
import com.serotonin.io.serial.SerialPortProxy;

/**
 * Class to allow virtual comm port to connect to a TCP/IP Port
 * @author tpacker
 *
 */
public class EthernetComBridge extends SerialPortProxy{

	private final static Log LOG = LogFactory.getLog(EthernetComBridge.class);
	 
	private String address;
	private int port;
	private int timeout = 1000;
	
	private Socket socket;
	
	public EthernetComBridge(String address, int port, int timeout) {
		super("ethernet-bridge");
		this.address = address;
		this.port = port;
		this.timeout = timeout;
	}

	@Override
	public byte[] readBytes(int i) throws SerialPortException {
		byte[] read = new byte[i];
		try {
			this.socket.getInputStream().read(read);
		} catch (IOException e) {
			throw new SerialPortException(e.getMessage());
		}
		return read;
	}

	@Override
	public void writeInt(int arg0) throws SerialPortException {
		
		try {
			this.socket.getOutputStream().write(arg0);
		} catch (IOException e) {
			throw new SerialPortException(e.getMessage());
		}
		
	}

	@Override
	public void closeImpl() throws SerialPortException {
		try {
			this.socket.close();
		} catch (IOException e) {
			LOG.error(e.getMessage(), e);
			throw new SerialPortException(e.getMessage());
		}
		
	}

	@Override
	public void openImpl() throws SerialPortException {
		try {
			this.socket = new Socket(this.address, this.port);
			this.socket.setSoTimeout(timeout);
		} catch (Exception e) {
			LOG.error(e.getMessage(), e);
			throw new SerialPortException(e);
		}

		
	}

	@Override
	public SerialPortInputStream getInputStream() {
		try{
			return new EthernetComBridgeInputStream(this.socket.getInputStream());
		}catch(IOException e){
			LOG.error(e.getMessage(), e);
			return null;
		}
	}

	@Override
	public SerialPortOutputStream getOutputStream() {
		try{
			return new EthernetComBridgeOutputStream(this.socket.getOutputStream());
		}catch(IOException e){
			LOG.error(e.getMessage(), e);
			return null;
		}
	}

	public InputStream getSocketInputStream() throws IOException{
		return this.socket.getInputStream();
	}
	
	public OutputStream getSocketOutputStream() throws IOException{
		return this.socket.getOutputStream();
	}
}
