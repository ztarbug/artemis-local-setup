package de.starwit;

import javax.jms.Connection;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageConsumer;
import javax.jms.MessageListener;
import javax.jms.Session;
import javax.jms.TextMessage;

import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class App {
    private static final Logger log = LogManager.getLogger(App.class);

    private static ActiveMQConnectionFactory factory;
    private static Connection connection;
    private static Session session;

    public static void main(String[] args) {
        String url = "tcp://127.0.0.1:61616";
        //url = "tcp://brain01.starwit.home:30062";
        url = "(tcp://127.0.0.1:61616,tcp://127.0.0.1:61617)?ha=true&reconnectAttempts=100";
        String user = "artemis";
        String pw = "artemis";

        factory = new ActiveMQConnectionFactory(url, user, pw);
        log.info("Is connection HA? " + factory.isHA());
        factory.setRetryInterval(500);
        factory.setRetryIntervalMultiplier(1.0);
        factory.setReconnectAttempts(-1);
        factory.setConfirmationWindowSize(10);
        //factory.setClientID("sample-client-"+factory.toString());

        try {
            connection = factory.createConnection();
            connection.start();
            session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
            MessageConsumer consumer = session.createConsumer(session.createQueue("broker-test"));
            consumer.setMessageListener(new MyListener());
            log.info("Connected to broker");
        } catch (JMSException e) {
            log.error("couldn't connect to broker " + url + " " + e.getMessage());
            e.printStackTrace();
        }

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            log.info("shutting down and closing ressources.");
            try {
                session.close();
                connection.close();
            } catch (JMSException e) {
                log.error("Couldn't close connection " + e.getMessage());
            }
            factory.close();
        }));
        
        while(true) {
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                log.warn("Message consuming Thread got interrupted " + e.getMessage());
            }
        }
    }

    private static class MyListener implements MessageListener {
        private final Logger log = LogManager.getLogger(this.getClass());

        @Override
        public void onMessage(Message message) {
            TextMessage msg = (TextMessage) message;
            try {
                log.info("received message" + msg.getText());
            } catch (JMSException e) {
                log.warn("Can't parse text message " + e.getMessage());
            }
        }
    }
}
