package apifirst;

import java.net.URI;

public class Main {

    public static void main(String[] args) {
        URI uri = URI.create("/hello/world");

        URI parent = uri.resolve("./");

        System.out.println(parent);
        System.out.println(parent);
    }

}
