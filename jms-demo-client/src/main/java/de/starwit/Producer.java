package de.starwit;

import javax.jms.Connection;
import javax.jms.JMSException;
import javax.jms.MessageProducer;
import javax.jms.Session;
import javax.jms.TextMessage;

import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;

public class Producer {
    //private static String url = "tcp://brain01.starwit.home:30062";
    private static String url = "tcp://127.0.0.1:61617";
    
    private static String user = "artemis";
    private static String pw = "artemis";

    private static ActiveMQConnectionFactory factory;
    public static void main( String[] args ) throws JMSException, InterruptedException {

        url = "(tcp://127.0.0.1:61616,tcp://127.0.0.1:61617)?ha=true&reconnectAttempts=100";

        factory = new ActiveMQConnectionFactory(url,user,pw);
        factory.setRetryInterval(500);
        factory.setRetryIntervalMultiplier(1.0);
        factory.setReconnectAttempts(-1);
        factory.setConfirmationWindowSize(10);

        Connection connection = factory.createConnection();
        connection.start();
        
        Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
        MessageProducer producer = session.createProducer(session.createQueue("broker-test"));

        for (int i = 0; i<500; i++) {
            TextMessage msg = session.createTextMessage("Test " + i);
            producer.send(msg);
            System.out.println("Message send " + i + " " + msg);
            Thread.sleep(100);
        }
        producer.close();
        session.close();
        connection.close();
    }

}
