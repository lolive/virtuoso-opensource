/*
 *  
 *  This file is part of the OpenLink Software Virtuoso Open-Source (VOS)
 *  project.
 *  
 *  Copyright (C) 1998-2006 OpenLink Software
 *  
 *  This project is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; only version 2 of the License, dated June 1991.
 *  
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 *  
 *  
*/
/* Driver.java */
package virtuoso.jdbc2;

import java.sql.*;
import java.util.*;

/**
 * The Virtuoso DBMS Driver class is an implementation of the Driver interface
 * in the JDBC API. It can be loaded in an application by :
 * <pre>
 *   <code>Class.forName("virtuoso.jdbc2.Driver")</code>
 * </pre>
 * , or statically with the -Djdbc.drivers=virtuoso.jdbc2.Driver on the java
 * interpreter command line, or in the java properties files with an entry like
 * before.
 * <u>Hints :</u> <ul>You can see the version of the current Virtuoso DBMS JDBC driver accessible in
 * the <i>CLASSPATH</i> with the <b>java virtuoso.jdbc2.Driver</b>
 * </ul>
 *
 * @version 1.0 (JDBC API 2.0 implementation)
 * @see java.sql.Driver
 * @see java.sql.DriverManager
 * @see virtuoso.jdbc2.VirtuosoConnection
 */
public class Driver implements java.sql.Driver
{
   // Specifically, it creates a new Driver instance and registers it.
   static
   {
      try
      {
         DriverManager.registerDriver(new Driver());
      }
      catch(Exception e)
      {
         e.printStackTrace();
      }
   }

   // The major and minor version number
   protected static final int major = 3;

   protected static final int minor = 25;

   // Some variables
   private String host, port, user, password, database, charset, pwdclear;
   private Integer timeout, log_enable;
#ifdef SSL
   private String keystore_cert, keystore_pass, keystore_path;
   private String ssl_provider;
#endif
   private Integer fbs, sendbs, recvbs;

   /**
    * Constructs a Virtuoso DBMS Driver instance. This function has not to be called
    * directly, this function is called only during the DriverManager registration
    * done with :
    * <pre>
    *   <code>Class.forName("virtuoso.jdbc2.Driver")</code>
    * </pre>
    *
    * @exception java.sql.SQLException an error occurred in registering
    */
   public Driver() throws SQLException
   {
     try
       {
	 String log_file = System.getProperty(
#if JDK_VER < 12
	     "JDBC_LOG"
#elif JDK_VER < 14
	     "JDBC2_LOG"
#else
	     "JDBC3_LOG"
#endif
	     );
	 //log_file="/home/O12/logs/log." + System.currentTimeMillis () + "." + new java.util.Random ().nextInt() + ".log";
	 if (log_file != null)
	   {
	     System.err.println ("RPC logfile=" + log_file);
	     try
	       {
		 VirtuosoFuture.rpc_log = new java.io.PrintStream (
		     new java.io.BufferedOutputStream (
		       new java.io.FileOutputStream (log_file), 4096));
	       }
	     catch (Exception e)
	       {
		 VirtuosoFuture.rpc_log = System.out;
	       }
	     //System.err.println ("rpc_log=" + VirtuosoFuture.rpc_log);
	   }
       }
     catch (Exception e)
       {
         VirtuosoFuture.rpc_log = null;
       }
   }

   // --------------------------- JDBC 1.0 ------------------------------
   /**
    * Attempts to make a database connection to the given URL.
    * The driver returns "null" if the URL given is not a Virtuoso DBMS JDBC
    * URL. A URL under the Virtuoso DBMS JDBC driver should be :
    * <pre>
    *   <code>jdbc:virtuoso://<i>host</i>:<i>port</i></code> , or
    *   <code>jdbc:virtuoso://<i>host</i>:<i>port</i>/UID=<i>username</i>/PWD=<i>userpassword</i></code>
    * </pre>
    * This function is only called through the DriverManager.getConnection function.
    *
    * @param url the URL of the database to which to connect
    * @param info a list of arbitrary string tag/value pairs as
    * connection arguments. Normally at least a "user" and
    * "password" property should be included.
    * @return a <code>Connection</code> object that represents a
    *         connection to the URL
    * @exception virtuoso.jdbc2.VirtuosoException it is the right
    * driver to connect to the given URL, but has trouble connecting to
    * the database.
    * @see java.sql.Connection#connect
    */
   public Connection connect(String url, Properties info) throws VirtuosoException
   {
      try
      {
         // First check the URL
         if(acceptsURL(url))
         {
            if(user!=null) info.put("user",user);
            if(password!=null) info.put("password",password);
            if(database!=null) info.put("database",database);
            if(timeout!=null) info.put("timeout",timeout);
            if(log_enable!=null) info.put("log_enable",log_enable);
            if(charset!=null) info.put("charset",charset);
            if(pwdclear!=null) info.put("pwdclear",pwdclear);
#ifdef SSL
            if(keystore_cert!=null) info.put("certificate",keystore_cert);
            if(keystore_pass!=null) info.put("keystorepass",keystore_pass);
            if(keystore_path!=null) info.put("keystorepath",keystore_path);
            if(ssl_provider!=null) info.put("provider",ssl_provider);
#endif
            if(fbs!=null) info.put("fbs",fbs);
            if(sendbs!=null) info.put("sendbs",sendbs);
            if(recvbs!=null) info.put("recvbs",recvbs);
	    //System.err.println ("PwdClear is " + pwdclear);
            return new VirtuosoConnection(url,host,Integer.parseInt(port),info);
         }
      }
      catch(NumberFormatException e)
      {
         throw new VirtuosoException("Wrong port number : " + e.getMessage(),VirtuosoException.BADFORMAT);
      }
      return null;
   }

   /**
    * Returns true if the driver thinks that it can open a connection
    * to the given URL.  Typically drivers will return true if they
    * understand the subprotocol specified in the URL and false if
    * they don't.
    *
    * @param url the URL of the database
    * @return true if this driver can connect to the given URL
    * @exception virtuoso.jdbc.VirtuosoException An internal error occurred.
    * @see java.sql.Connection#acceptsURL
    */
   public boolean acceptsURL(String url) throws VirtuosoException
   {
      int i, j;
      // Set some variables to null
      host = "localhost";
      port = "1111";
      charset = null;
      pwdclear = null;
#ifdef SSL
      keystore_cert = keystore_pass = keystore_path = null;
#endif
      database = user = password = null;
      fbs = new Integer(VirtuosoTypes.DEFAULTPREFETCH);
      recvbs = sendbs = new Integer(32768);

      if((i = url.indexOf("//")) > 0)
      {
         String part1 = url.substring(0,i), part2 = url.substring(i + 2);
         // Check the name of the driver
         if(!part1.equalsIgnoreCase("jdbc:virtuoso:"))
            return false;
         // Get the hostname and port
         if((i = part2.indexOf(":")) >= 0)
         {
            host = part2.substring(0,i);
            part2 = part2.substring(i + 1);
         }
         else
         {
            if((j = part2.indexOf("/")) < 0)
            {
               host = part2.substring(0);
               return true;
            }
            host = part2.substring(0,j);
            part2 = part2.substring(j);
         }
         if((j = part2.indexOf("/")) < 0)
         {
            port = part2.substring(0);
            return true;
         }
         else
           if(j != 0 )
           {
              port = part2.substring(0,j);
              part2 = part2.substring(j);
           }
#ifdef SSL
         if((j = part2.toLowerCase().indexOf("/provider=")) >= 0)
            ssl_provider = (part2.substring(j + 10).indexOf("/") < 0) ? part2.substring(j + 10) :
                part2.substring(j + 10,j + 10 + part2.substring(j + 10).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/cert=")) >= 0)
            keystore_cert = (part2.substring(j + 6).indexOf("/") < 0) ? part2.substring(j + 6) :
                part2.substring(j + 6,j + 6 + part2.substring(j + 6).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/pass=")) >= 0)
            keystore_pass = (part2.substring(j + 6).indexOf("/") < 0) ? part2.substring(j + 6) :
                part2.substring(j + 6,j + 6 + part2.substring(j + 6).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/kpath=")) >= 0)
	 {
            char fsep = System.getProperty("file.separator").charAt(0);
            keystore_path = (part2.substring(j + 7).indexOf("/") < 0) ? part2.substring(j + 7) :
                part2.substring(j + 7,j + 7 + part2.substring(j + 7).indexOf("/"));
            if(fsep != '\\')
	        keystore_path = keystore_path.replace('\\', fsep);
         }
	 if((j = part2.toLowerCase().indexOf("/ssl")) >= 0)
            keystore_cert = (keystore_cert == null) ? "" : keystore_cert;
#endif
         if((j = part2.toLowerCase().indexOf("/database=")) >= 0)
            database = (part2.substring(j + 10).indexOf("/") < 0) ? part2.substring(j + 10) :
                part2.substring(j + 10,j + 10 + part2.substring(j + 10).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/uid=")) >= 0)
            user = (part2.substring(j + 5).indexOf("/") < 0) ? part2.substring(j + 5) :
                part2.substring(j + 5,j + 5 + part2.substring(j + 5).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/pwd=")) >= 0)
            password = (part2.substring(j + 5).indexOf("/") < 0) ? part2.substring(j + 5) :
                part2.substring(j + 5,j + 5 + part2.substring(j + 5).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/timeout=")) >= 0)
            timeout = new Integer((part2.substring(j + 9).indexOf("/") < 0) ? part2.substring(j + 9) :
                part2.substring(j + 9,j + 9 + part2.substring(j + 9).indexOf("/")));
         if((j = part2.toLowerCase().indexOf("/log_enable=")) >= 0)
            log_enable = new Integer((part2.substring(j + 12).indexOf("/") < 0) ? part2.substring(j + 12) :
                part2.substring(j + 12, j + 12 + part2.substring(j + 12).indexOf("/")));
         if((j = part2.toLowerCase().indexOf("/charset=")) >= 0)
            charset = (part2.substring(j + 9).indexOf("/") < 0) ? part2.substring(j + 9) :
                part2.substring(j + 9,j + 9 + part2.substring(j + 9).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/pwdtype=")) >= 0)
            pwdclear = (part2.substring(j + 9).indexOf("/") < 0) ? part2.substring(j + 9) :
                part2.substring(j + 9,j + 9 + part2.substring(j + 9).indexOf("/"));
         if((j = part2.toLowerCase().indexOf("/fbs=")) >= 0)
            fbs = new Integer((part2.substring(j + 5).indexOf("/") < 0) ? part2.substring(j + 5) :
                part2.substring(j + 5,j + 5 + part2.substring(j + 5).indexOf("/")));
         if((j = part2.toLowerCase().indexOf("/sendbs=")) >= 0)
            sendbs = new Integer((part2.substring(j + 8).indexOf("/") < 0) ? part2.substring(j + 8) :
                part2.substring(j + 8,j + 8 + part2.substring(j + 8).indexOf("/")));
         if((j = part2.toLowerCase().indexOf("/recvbs=")) >= 0)
            recvbs = new Integer((part2.substring(j + 8).indexOf("/") < 0) ? part2.substring(j + 8) :
                part2.substring(j + 8,j + 8 + part2.substring(j + 8).indexOf("/")));
	 //System.err.println ("2PwdClear is " + pwdclear);
      }
      else
         if(!url.equalsIgnoreCase("jdbc:virtuoso"))
            return false;
      return true;
   }

   /**
    * Gets information about the possible properties for this driver.
    * <p>The getPropertyInfo method is intended to allow a generic GUI tool to
    * discover what properties it should prompt a human for in order to get
    * enough information to connect to a database.  Note that depending on
    * the values the human has supplied so far, additional values may become
    * necessary, so it may be necessary to iterate though several calls
    * to getPropertyInfo.
    *
    * @param url the URL of the database to which to connect
    * @param info a proposed list of tag/value pairs that will be sent on
    *          connect open
    * @return an array of DriverPropertyInfo objects describing possible
    *          properties.  This array may be an empty array if no properties
    *          are required.
    * @exception virtuoso.jdbc2.VirtuosoException An internal error occurred.
    * @see java.sql.Connection#getPropertyInfo
    */
   public DriverPropertyInfo[] getPropertyInfo(String url, Properties info) throws VirtuosoException
   {
      // First check the URL
      if(acceptsURL(url))
      {
         DriverPropertyInfo[] pinfo = new DriverPropertyInfo[7];
         if(info.get("user") == null)
         {
            pinfo[0] = new DriverPropertyInfo("user",null);
            pinfo[0].required = true;
         }
         if(info.get("password") == null)
         {
            pinfo[1] = new DriverPropertyInfo("password",null);
            pinfo[1].required = true;
         }
         if(info.get("database") == null)
         {
            pinfo[2] = new DriverPropertyInfo("database",null);
            pinfo[2].required = false;
         }
#ifdef SSL
         if(info.get("certificate") == null)
         {
            pinfo[3] = new DriverPropertyInfo("certificate",null);
            pinfo[3].required = false;
         }
         if(info.get("keystorepass") == null)
         {
            pinfo[4] = new DriverPropertyInfo("keystorepass",null);
            pinfo[4].required = false;
         }
         if(info.get("keystorepath") == null)
         {
            pinfo[5] = new DriverPropertyInfo("keystorepath",null);
            pinfo[5].required = false;
         }
         if(info.get("provider") == null)
         {
            pinfo[6] = new DriverPropertyInfo("provider",null);
            pinfo[6].required = false;
         }
#endif
         return pinfo;
      }
      DriverPropertyInfo[] pinfo = new DriverPropertyInfo[8];
      pinfo[0] = new DriverPropertyInfo("url",url);
      pinfo[0].required = true;
      if(info.get("user") == null)
      {
         pinfo[1] = new DriverPropertyInfo("user",null);
         pinfo[1].required = true;
      }
      if(info.get("password") == null)
      {
         pinfo[2] = new DriverPropertyInfo("password",null);
         pinfo[2].required = true;
      }
      if(info.get("database") == null)
      {
         pinfo[3] = new DriverPropertyInfo("database",null);
         pinfo[3].required = false;
      }
#ifdef SSL
      if(info.get("certificate") == null)
      {
         pinfo[4] = new DriverPropertyInfo("certificate",null);
         pinfo[4].required = false;
      }
      if(info.get("keystorepass") == null)
      {
         pinfo[5] = new DriverPropertyInfo("keystorepass",null);
         pinfo[5].required = false;
      }
      if(info.get("keystorepath") == null)
      {
         pinfo[6] = new DriverPropertyInfo("keystorepath",null);
         pinfo[6].required = false;
      }
      if(info.get("provider") == null)
      {
         pinfo[7] = new DriverPropertyInfo("provider",null);
         pinfo[7].required = false;
      }
#endif
      if(info.get("fbs") == null)
      {
         pinfo[3] = new DriverPropertyInfo("fbs",null);
         pinfo[3].required = false;
      }
      if(info.get("sendbs") == null)
      {
         pinfo[3] = new DriverPropertyInfo("sendbs",null);
         pinfo[3].required = false;
      }
      if(info.get("recvbs") == null)
      {
         pinfo[3] = new DriverPropertyInfo("recvbs",null);
         pinfo[3].required = false;
      }
      return pinfo;
   }

   /**
    * Gets the driver's major version number.
    *
    * @return this driver's major version number
    */
   public int getMajorVersion()
   {
      return major;
   }

   /**
    * Gets the driver's minor version number.
    *
    * @return this driver's minor version number
    */
   public int getMinorVersion()
   {
      return minor;
   }

   /**
    * Reports whether this driver is a genuine JDBC COMPLIANT driver.
    *
    * @return true if the JDBC Driver is compliant, false otherwise ... but
    * our Virtuoso DBMS JDBC driver is compliant, so true is always returned.
    */
   public boolean jdbcCompliant()
   {
      return true;
   }

   public static void main(String args[])
   {
#ifdef SSL
      System.out.println("OpenLink Virtuoso(TM) Driver with SSL support for JDBC(TM) Version " + VIRT_JDBC_VER + " [Build " + major + "." + minor + "]");
#else
      System.out.println("OpenLink Virtuoso(TM) Driver for JDBC(TM) Version " + VIRT_JDBC_VER + " [Build " + major + "." + minor + "]");
#endif
   }

}
