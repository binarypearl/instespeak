import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringReader;
import java.net.ServerSocket;
import java.net.Socket;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import opennlp.tools.cmdline.postag.POSModelLoader;
import opennlp.tools.postag.POSModel;
import opennlp.tools.postag.POSSample;
import opennlp.tools.postag.POSTaggerME;
import opennlp.tools.tokenize.WhitespaceTokenizer;
import opennlp.tools.util.ObjectStream;
import opennlp.tools.util.PlainTextByLineStream;

public class PosTagger {
	
	//private POSModel model;
	static POSModel model = new POSModelLoader().load(new File ("/mnt/projects/speech/apache-opennlp-1.5.3/bin/en-pos-maxent.bin"));
	static POSTaggerME tagger = new POSTaggerME (model);
	
	static String string_log_level = "";
	static String string_project_directory = "";

	public static void main (String args[]) throws IOException {
		// First we need to look at the config file to see what our loglevel is and
		// where we can get our project directory from the config file
		
		try {			
			String record = "";
			Pattern pattern_config_file_log_level = Pattern.compile ("(log_level)(\\s*)(=)(\\s*)(.*)", Pattern.CASE_INSENSITIVE);
			Pattern pattern_config_file_project_directory = Pattern.compile ("(project_directory)(\\s*)(=)(\\s*)(.*)", Pattern.CASE_INSENSITIVE);
			
			FileReader file_reader_config_file = new FileReader ("/etc/instespeak.cfg");
			
			BufferedReader buffered_reader_config_file = new BufferedReader (file_reader_config_file);
			
			while ((record = buffered_reader_config_file.readLine()) != null) {
				// Do a regex matching here to find our key/value pairs
				Matcher matcher_config_file_log_level = pattern_config_file_log_level.matcher(record);
				Matcher matcher_config_file_project_directory = pattern_config_file_project_directory.matcher(record);
				
				if (matcher_config_file_log_level.find()) {
					string_log_level = matcher_config_file_log_level.group(5);
					
					string_log_level = string_log_level.replaceAll("\"", "");
				}
				
				else if (matcher_config_file_project_directory.find()) {
					string_project_directory = matcher_config_file_project_directory.group(5);
					
					string_project_directory = string_project_directory.replaceAll("\"", "");
				}
				
			}
			
			file_reader_config_file.close();
			
			//System.out.println ("I think my log level is: " + string_log_level);
			//System.out.println ("I think my project directory is: " + string_project_directory);
		}
		
		catch (IOException ioe) {
			System.err.println ("Error opening /etc/instespeak.cfg: " + ioe.getMessage());
		}
		
		
		try {
			FileWriter file_writer_log_file = new FileWriter (string_project_directory + "/logs/PosTagger.log", true);

			DateFormat date_format = new SimpleDateFormat ("dd/MM/yyyy HH:mm:ss");
			Date date = new Date();
			
			int port_number = 9999;
		
			ServerSocket server_socket = new ServerSocket (port_number);

			// Let's write some into stuff into the log file:
			file_writer_log_file.write ("====================================================================================================\n");
			file_writer_log_file.write ("Welcome to PosTagger - version 0.01\n");
			file_writer_log_file.write ("Date and time: " + date_format.format(date) + "\n");
			file_writer_log_file.write ("====================================================================================================\n\n");
			
			file_writer_log_file.write ("Starting socket on port " + port_number + "\n");
			file_writer_log_file.flush();
			
			try {
				file_writer_log_file.write("stage 0\n");
				
				while (true) {
					Socket socket = server_socket.accept();
					
					file_writer_log_file.write ("stage 1\n");
					
					try {
						file_writer_log_file.write ("stage 2\n");
						// This is how we send data back over to the client.
						// out.println("message") 
						PrintWriter out = new PrintWriter (socket.getOutputStream(), true);
						
						// This is how we get the contents of the message being sent over the socket.  
						// in.readline() will give us the entire message sent.
						BufferedReader in = new BufferedReader (new InputStreamReader (socket.getInputStream()));			
						
						// Regex stuff here:
						
						String string_message_from_socket = in.readLine();
						//System.out.println ("From Perl: " + string_message_from_socket);
						file_writer_log_file.write ("----------------------------------------------------------------------------------------------------\n");
						file_writer_log_file.write ("Message from instespeak.pl: " + string_message_from_socket + "\n");
						
						/*
						String string_regex_message_from_socket_testing = "(testing)(:)(.*)";
						Pattern pattern_message_from_socket_testing = Pattern.compile(string_regex_message_from_socket_testing, Pattern.CASE_INSENSITIVE);
						
						Matcher matcher_object_testing = pattern_message_from_socket_testing.matcher(string_message_from_socket);
						
						if (matcher_object_testing.find()) {
							out.println ("yes I am\n");
						}
						*/
						String string_regex_message_from_socket = "(text)(:)(.*)";
						Pattern pattern_message_from_socket = Pattern.compile(string_regex_message_from_socket, Pattern.CASE_INSENSITIVE);
						
						Matcher matcher_object = pattern_message_from_socket.matcher(string_message_from_socket);
						
						if (matcher_object.find()) {
							System.out.println ("We got the match.");
							System.out.println ("First arg: " + matcher_object.group(1));
							System.out.println ("Secon arg: " + matcher_object.group(2));
							System.out.println ("Third arg: " + matcher_object.group(3));

							String command = matcher_object.group(1);
							String arguments = matcher_object.group(3);
							
							if (command.equals("text")) {
								ObjectStream<String> lineStream = new PlainTextByLineStream (new StringReader(arguments));
								
								String line;
								while ((line = lineStream.read()) != null) {
									String whitespaceTokenizerLine[] = WhitespaceTokenizer.INSTANCE.tokenize(line);
									String tags[] = tagger.tag(whitespaceTokenizerLine);
									
									POSSample sample = new POSSample(whitespaceTokenizerLine, tags);
									
									//System.out.println ("Here is what we are passing back to perl: " + sample.toString());
									file_writer_log_file.write ("Passing this back to instespeak.pl: " + sample.toString() + "\n");
									out.println (sample.toString());
								}
								
							}
						}
						
						else {
							//System.out.println ("sorry no match.");
							file_writer_log_file.write ("Sorry no match.\n");
						}
					}
					
					catch (IOException ioe) {
						file_writer_log_file.write ("nmap scan1?\n");
						System.out.println ("nmap scan1?\n");
					}	
					
					
					finally {
							socket.close();
					}
					
					file_writer_log_file.write ("----------------------------------------------------------------------------------------------------\n\n");
					file_writer_log_file.flush();
				}
			}
			
			catch (IOException ioe) {
				file_writer_log_file.write ("nmap scan2?\n");
				System.out.println ("nmap scan2?\n");
			}
		
			finally {
				server_socket.close();
			
				//System.out.println ("Stopping socket that was on port " + port_number);
				file_writer_log_file.write("Stopping socket that was on port " + port_number + "\n");
				file_writer_log_file.flush();
				
				file_writer_log_file.close();
			}
		}
		
		catch (IOException ioe) {
			System.err.println ("IOException: " + ioe.getMessage());
		}
	}	
}


