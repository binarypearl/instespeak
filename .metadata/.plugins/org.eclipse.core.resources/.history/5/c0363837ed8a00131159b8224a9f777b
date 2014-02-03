import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringReader;
import java.net.ServerSocket;
import java.net.Socket;
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
	
	public static void main (String args[]) throws IOException {
		int port_number = 9999;
		
		ServerSocket server_socket = new ServerSocket (port_number);
		
		System.out.println ("Staring socket on port " + port_number);
		
		try {
			while (true) {
					Socket socket = server_socket.accept();
					
					try {
						// This is how we send data back over to the client.
						// out.println("message") 
						PrintWriter out = new PrintWriter (socket.getOutputStream(), true);
						
						// This is how we get the contents of the message being sent over the socket.  
						// in.readline() will give us the entire message sent.
						BufferedReader in = new BufferedReader (new InputStreamReader (socket.getInputStream()));			
						
						// Regex stuff here:
						
						String string_message_from_socket = in.readLine();
						System.out.println ("From Perl: " + string_message_from_socket);
						
						String string_regex_message_from_socket = "(text)(:)(.*)";
						Pattern pattern_message_from_socket = Pattern.compile(string_regex_message_from_socket, Pattern.CASE_INSENSITIVE);
						
						Matcher matcher_object = pattern_message_from_socket.matcher(string_message_from_socket);
						
						if (matcher_object.find()) {
							//System.out.println ("We got the match.");
							//System.out.println ("First arg: " + matcher_object.group(1));
							//System.out.println ("Secon arg: " + matcher_object.group(2));
							//System.out.println ("Third arg: " + matcher_object.group(3));

							String command = matcher_object.group(1);
							String arguments = matcher_object.group(3);
							
							if (command.equals("text")) {
								ObjectStream<String> lineStream = new PlainTextByLineStream (new StringReader(arguments));
								
								String line;
								while ((line = lineStream.read()) != null) {
									String whitespaceTokenizerLine[] = WhitespaceTokenizer.INSTANCE.tokenize(line);
									String tags[] = tagger.tag(whitespaceTokenizerLine);
									
									POSSample sample = new POSSample(whitespaceTokenizerLine, tags);
									
									System.out.println ("Here is what we are passing back to perl: " + sample.toString());
									out.println (sample.toString());
								}
								
							}
						}
						
						else {
							System.out.println ("sorry no match.");
						}
						
						
					}
					
					finally {
							socket.close();
					}
			}
		}
		
		finally {
			server_socket.close();
			
			System.out.println ("Stopping socket that was on port " + port_number);
		}
	}	
}


