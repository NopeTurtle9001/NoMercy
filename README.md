# NoMercy
NoMercy is a plugin that is used to Discipline users on any Roblox experience. It stores the id of the user, the ban reason, and the experience the user was banned in to allow experience owners to make their games a safer experience for their community.


## UPDATE
Will not be updating this plugin anymore since Roblox blocks HTTP Requests specifaclly the request this plugin attempts to make to the Github REST API to update the banlist.
**Why This Happens**  
Roblox’s HTTPService has strict outbound request limitations for security and compliance reasons. These include:  
- **Blocked Domains & Ports** – Direct requests to certain domains (like `api.github.com`) are disallowed to prevent abuse or data exfiltration.  
- **Authentication Restrictions** – GitHub’s REST API requires OAuth tokens or personal access tokens for commit operations, but Roblox blocks sending these directly in HTTP headers to unapproved domains.  
- **Rate & Method Controls** – Roblox limits certain HTTP methods (e.g., `PATCH`, `PUT`, `DELETE`) and large payloads, which are necessary for committing changes to a repository.  

Because of these constraints, direct in-game HTTP calls to GitHub’s API for writes/commits are effectively blocked.

---

**Recommended Alternative via a Third Party (e.g., Cloudflare)**  
To work around these restrictions, consider introducing an **intermediary service** that Roblox *can* communicate with, which then talks to this GitHub or any other Github for you:  

1. **Use Cloudflare Workers**  
   - Deploy a lightweight Worker script that accepts simple, authenticated requests from Roblox.  
   - Worker then performs the authenticated GitHub REST API call (commit, push, update banlist).  
   - Advantage: No direct token exposure to Roblox; tokens live only in Cloudflare’s secure environment.

2. **Custom API Gateway** (Cloudflare, AWS API Gateway, or similar)  
   - Roblox sends POST requests with ban updates to the gateway.  
   - The gateway runs server-side code to update the GitHub repo.  

3. **Queue & Process Model**  
   - Send ban entries from Roblox to a Cloudflare Worker or small backend.  
   - Batch and commit these updates periodically to GitHub to avoid rate limit hits.  

---

Finally, thanks for staying along the way. If you have any questions about my code or how this system works reach out to me via email @NopeTurtle91@gmail.com ot Discord via nopeturtle.

If you’d like, I can **draft a Cloudflare Worker example** that securely receives Roblox requests and commits to a GitHub repo without exposing your credentials. That would give you a working drop-in bridge for your banlist updates.
