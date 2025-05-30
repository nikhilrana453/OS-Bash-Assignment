
# OS Assignment
**Author:** Nikhil 
**Student ID:** 1000122193  
**Last Updated:** 30/05/2025  

This repository contains an OS assignment focused on user management and backup automation within a Dockerized Ubuntu environment.


## Step-by-Step Guide: User Management and Backup Automation in Docker Ubuntu

### **Step 1: Set up Docker Container**

1. **To create and start the container**
  
   docker run -it --name bash_assignment ubuntu:latest bash
   
2. **start the container using this command**
   
   docker start -ai bash_assignment
   
   This will start the container 

### **Step 2: Install Required Packages**

Once inside the container, run the following command to install the necessary packages:
   
   apt update && apt install -y sudo curl wget 
   
### **Step 3: Clone the Git Repository**

1. **Create a directory to store the project:**
   mkdir Bash_Scripting_Assignment
   cd Bash_Scripting_Assignment

2. **Clone repository:**   git clone https://github.com/nikhilrana453/OS-Bash-Assignment

3. **Alternatively, you can clone the repository directly to your home directory:**
   git clone https://github.com/nikhilrana453/OS-Bash-Assignment

4. ** use:**
  
   git init

### **Step 4: User Creation (Task 1)**

1. **Navigate to the task1 directory:**
   cd /mydata/Bash_Scripting_Assignment/task1

2. **Run the user setup script to create users from users.csv:**
   
   ./user_setup.sh users.csv
   This will create users from the CSV file and set their password to their birth month and year (MMYYYY).

3. **Verify User Creation:**
   - To check the created users, run:
     cat /etc/passwd
   - To switch to a user, use:
     su - <username>
   - Use the birth month and year (MMYYYY) as the password.

### **Step 5: Backup Automation (Task 2)**

1. **Navigate to the task2 directory:**
   cd /mydata/Bash_Scripting_Assignment/task2

2. **Run the backup script:**
   ./backup.sh
   The script will prompt you to enter the source and backup directories. Provide the paths to back up the selected directory.

3. **Verify Backups:**
   To list backup files:
   ls -lh /backup/

4. **Extract a Backup (if needed):**
   tar -xzf /backup/backup_home_<timestamp>.tar.gz -C /destination_directory/
   Replace `<timestamp>` with the correct timestamp from backup file and `/destination_directory/` with the target path.

### **Step 6: Logging**
1. **To check logs for user creation (Task 1), run:**
   cat /var/log/user_script.log
## 2. To check logs for backup files
   cat /var/log/backup_script.log
  
### **Step 7: Exit the Container**

 exit the Docker container by running:
   exit

