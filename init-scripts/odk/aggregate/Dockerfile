FROM tomcat:8-jre8  

#RUN echo "export JAVA_OPTS=\"-Dapp.env=staging\"" > /usr/local/tomcat/bin/setenv.sh  
RUN /bin/bash -c 'rm -rf /usr/local/tomcat/webapps/ROOT'

COPY ./ROOT.war /usr/local/tomcat/webapps/

CMD ["catalina.sh", "run"]  
